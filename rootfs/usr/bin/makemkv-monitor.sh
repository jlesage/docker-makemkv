#!/bin/sh
# MakeMKV output monitor with optional notifications

# Check if apprise config exists
if [ ! -f "/config/apprise.yml" ]; then
    # No config = just pass through the output for docker logs
    while IFS= read -r line; do
        echo "$line"
    done
    exit 0
fi

# Function to send notification via Python script
send_notification() {
    local type="$1"
    local title="$2"
    local details="$3"
    
    # Call Python notification handler
    python3 /usr/bin/makemkv-notify.py "$type" "$title" "$details" 2>/dev/null
}

# State tracking
CURRENT_TITLE=""
CURRENT_FILE=""
MOVIE_TITLE=""
ERRORS_COUNT=0
ERROR_TYPE=""
START_TIME=""

# Process MakeMKV output line by line
while IFS= read -r line; do
    # Echo to stdout so tee can still capture it
    echo "$line"
    
    # Detect disc scanning/opening (currently not used for notifications)
    # Keeping this in case we want to track disc name for other purposes
    if echo "$line" | grep -q "Opening DVD\|Opening Blu-ray\|Scanning title"; then
        DISC_NAME=$(echo "$line" | grep -oE '"[^"]+"' | head -1 | tr -d '"' || echo "Unknown")
        # Don't set START_TIME here - wait for actual rip start
    fi
    
    # Detect actual rip starting - "Saving X titles into directory"
    if echo "$line" | grep -q "Saving.*titles into directory"; then
        START_TIME=$(date +%s)
        TITLE_COUNT=$(echo "$line" | grep -oE "Saving [0-9]+" | grep -oE "[0-9]+")
        OUTPUT_DIR=$(echo "$line" | grep -oE "directory.*" | sed 's/directory //' | sed 's|file://||')
        # Extract just the movie title from the path (last component)
        MOVIE_TITLE=$(echo "$OUTPUT_DIR" | sed 's|.*/||')
        
        # Only send start notification if enabled
        if is-bool-val-true "${NOTIFY_START:-1}"; then
            send_notification "start" "$MOVIE_TITLE" "📁 \`$OUTPUT_DIR\`\\n📀 Saving \`$TITLE_COUNT\` title(s)"
        fi
    fi
    
    # Detect title being processed
    if echo "$line" | grep -q "Processing.*playlist\|Saving.*titles"; then
        CURRENT_TITLE=$(echo "$line" | grep -oE 'playlist [0-9]+|title [0-9]+' | head -1 || echo "")
        [ ! -z "$CURRENT_TITLE" ] && send_notification "progress" "Processing" "📝 Working on $CURRENT_TITLE"
    fi
    
    # Detect output file creation
    if echo "$line" | grep -q "Saving to.*\.mkv"; then
        CURRENT_FILE=$(echo "$line" | grep -oE '[^/]+\.mkv' | head -1 || echo "")
        send_notification "progress" "Saving" "💾 Creating file: \`$CURRENT_FILE\`"
    fi
    
    # Detect completion - "Copy complete" is the definitive marker
    if echo "$line" | grep -q "Copy complete"; then
        # Extract saved and failed counts
        SAVED_COUNT=$(echo "$line" | grep -oE "[0-9]+ titles saved" | grep -oE "^[0-9]+" || echo "0")
        FAILED_COUNT=$(echo "$line" | grep -oE "[0-9]+ failed" | grep -oE "^[0-9]+" || echo "0")
        
        END_TIME=$(date +%s)
        if [ ! -z "$START_TIME" ]; then
            DURATION=$((END_TIME - START_TIME))
            DURATION_HOURS=$((DURATION / 3600))
            DURATION_MINS=$(((DURATION % 3600) / 60))
            DURATION_SECS=$((DURATION % 60))
            
            # Format as HH:MM:SS or MM:SS if less than an hour
            if [ $DURATION_HOURS -gt 0 ]; then
                TIME_STR=$(printf "%02d:%02d:%02d" $DURATION_HOURS $DURATION_MINS $DURATION_SECS)
            else
                TIME_STR=$(printf "%02d:%02d" $DURATION_MINS $DURATION_SECS)
            fi
        else
            TIME_STR="Unknown"
        fi
        
        # Determine notification type based on counts
        if [ "$SAVED_COUNT" = "0" ] && [ "$FAILED_COUNT" != "0" ]; then
            # Complete failure
            ERROR_DETAIL="✅ Saved: \`0\` titles\\n"
            ERROR_DETAIL="${ERROR_DETAIL}❌ Failed: \`$FAILED_COUNT\` titles\\n"
            [ "$ERRORS_COUNT" -gt 0 ] && [ ! -z "$ERROR_TYPE" ] && ERROR_DETAIL="${ERROR_DETAIL}⚠️ \`$ERRORS_COUNT\` $ERROR_TYPE errors\\n"
            ERROR_DETAIL="${ERROR_DETAIL}⏱️ Duration: \`$TIME_STR\`"
            
            send_notification "error" "${MOVIE_TITLE:-Unknown Title}" "$ERROR_DETAIL"
            
        elif [ "$SAVED_COUNT" != "0" ] && [ "$FAILED_COUNT" != "0" ]; then
            # Partial success
            PARTIAL_INFO="✅ Saved: \`$SAVED_COUNT\` titles\\n"
            PARTIAL_INFO="${PARTIAL_INFO}❌ Failed: \`$FAILED_COUNT\` titles\\n"
            [ "$ERRORS_COUNT" -gt 0 ] && [ ! -z "$ERROR_TYPE" ] && PARTIAL_INFO="${PARTIAL_INFO}⚠️ \`$ERRORS_COUNT\` $ERROR_TYPE errors\\n"
            PARTIAL_INFO="${PARTIAL_INFO}⏱️ Duration: \`$TIME_STR\`"
            
            send_notification "error" "${MOVIE_TITLE:-Unknown Title}" "$PARTIAL_INFO"
            
        elif [ "$SAVED_COUNT" != "0" ]; then
            # Complete success
            FILE_INFO="✅ Saved: \`$SAVED_COUNT\` titles\\n"
            FILE_INFO="${FILE_INFO}⏱️ Duration: \`$TIME_STR\`"
            
            send_notification "success" "${MOVIE_TITLE:-Unknown Title}" "$FILE_INFO"
        fi
        
        # Reset state
        CURRENT_TITLE=""
        CURRENT_FILE=""
        MOVIE_TITLE=""
        START_TIME=""
        ERRORS_COUNT=0
        ERROR_TYPE=""
    fi
    
    # Track specific error types
    if echo "$line" | grep -q "Failed to save title"; then
        LAST_ERROR_MSG=$(echo "$line" | cut -c1-200)
    fi
    
    if echo "$line" | grep -q "Encountered.*errors of type"; then
        ERROR_TYPE=$(echo "$line" | grep -oE "of type '[^']+'" | cut -d"'" -f2)
        ERROR_COUNT=$(echo "$line" | grep -oE "Encountered [0-9]+" | grep -oE "[0-9]+")
        ERRORS_COUNT=$ERROR_COUNT
        ERROR_SUMMARY="$ERROR_COUNT errors of type '$ERROR_TYPE'"
    fi
    
    # Track hash check failures silently (they're common with dirty discs)
    if echo "$line" | grep -q "Hash check failed"; then
        ERRORS_COUNT=$((ERRORS_COUNT + 1))
    fi
done