#!/usr/bin/env python3
"""
Notification handler for MakeMKV using Apprise
Configure via /config/apprise.yml
"""

import sys
import os
from apprise import Apprise, AppriseConfig

def send_notification(notification_type, title, details):
    """Send notification via Apprise config"""
    
    # Create Apprise instance
    apobj = Apprise()
    
    # Load config file (required for notifications)
    config_file = '/config/apprise.yml'
    if not os.path.exists(config_file):
        # No config = no notifications, just exit silently
        return
    
    config = AppriseConfig()
    config.add(config_file)
    apobj.add(config)
    
    # If no services configured, exit silently
    if len(apobj) == 0:
        return
    
    # Format message based on type
    if notification_type == 'start':
        header = 'Rip Started'
    elif notification_type == 'success':
        header = 'Rip Complete'
    elif notification_type == 'error':
        header = 'Rip Failed'
    elif notification_type == 'partial':
        header = 'Rip Partially Completed'
    else:
        header = 'MakeMKV Update'
    
    # Build cleaner message body
    message_parts = []
    
    # Always use movie icon with title
    if title:
        message_parts.append(f"🎬 **{title}**")
    
    # Process details - replace literal \n with actual newlines
    if details:
        details = details.replace('\\n', '\n')
        message_parts.append(details)
    
    body = '\n'.join(message_parts) if message_parts else header
    
    # Send notification with clean title (no icon)
    apobj.notify(
        body=body,
        title=header,
        body_format='markdown'
    )

if __name__ == '__main__':
    # Read arguments from command line
    if len(sys.argv) < 4:
        print("Usage: notify.py <type> <title> <details>", file=sys.stderr)
        sys.exit(1)
    
    notification_type = sys.argv[1]
    title = sys.argv[2]
    details = sys.argv[3]
    
    send_notification(notification_type, title, details)