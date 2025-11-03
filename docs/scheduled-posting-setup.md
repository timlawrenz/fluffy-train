# Scheduled Posting Setup Guide

This guide explains how to set up automated scheduled posting using cron.

## Overview

The scheduler runs hourly and posts any photos that were scheduled for posting within the last hour. This ensures posts go out close to their optimal calculated times.

## How It Works

1. **Create Scheduled Posts** - Creates draft posts with optimal_time_calculated
2. **Cron Runs Hourly** - Checks for posts due within the last hour
3. **Posts to Instagram** - Automatically posts and updates status
4. **Records History** - Tracks in content strategy history

## Setup Instructions

### 1. Test the Script Manually

Before setting up cron, test that everything works:

```bash
# Test the wrapper script
cd /home/tim/source/activity/fluffy-train
./bin/scheduled_posting.sh
```

You should see output indicating no scheduled posts (since we haven't created any yet).

### 2. Create a Test Scheduled Post

```bash
# Create a scheduled post for sarah
cd /home/tim/source/activity/fluffy-train
bundle exec rails scheduling:create_scheduled_post[sarah]
```

This will:
- Use content strategy to select optimal photo
- Calculate optimal posting time
- Create a draft post with status='draft'
- Show you when it will be posted

### 3. Test Posting Scheduled Posts

```bash
# Manually trigger the scheduled post task
bundle exec rails scheduling:post_scheduled
```

If a post was scheduled for within the last hour, it will be posted.

### 4. Set Up Cron

Edit your crontab:

```bash
crontab -e
```

Add this line to run every hour:

```cron
0 * * * * /home/tim/source/activity/fluffy-train/bin/scheduled_posting.sh
```

**Or run every 30 minutes** for more precise timing:

```cron
0,30 * * * * /home/tim/source/activity/fluffy-train/bin/scheduled_posting.sh
```

**Or run at specific times** (e.g., 6 AM, 9 AM, 12 PM, 3 PM, 6 PM):

```cron
0 6,9,12,15,18 * * * /home/tim/source/activity/fluffy-train/bin/scheduled_posting.sh
```

### 5. Verify Cron Setup

Check that your cron job is registered:

```bash
crontab -l
```

Check the logs after the next scheduled run:

```bash
tail -f /home/tim/source/activity/fluffy-train/log/scheduled_posting.log
```

## Daily Workflow Options

### Option A: Pre-schedule Posts (Recommended)

Schedule posts in advance, let cron handle the timing:

```bash
# Morning: Create scheduled posts for the day/week
bundle exec rails scheduling:create_scheduled_post[sarah]

# Cron will automatically post them at optimal times
```

### Option B: Immediate Posting (Current Method)

Continue manual posting as before:

```bash
# Posts immediately
bundle exec rails scheduling:post_with_strategy[sarah]
```

### Option C: Hybrid Approach

Mix both methods:
- Use scheduled posts for regular content
- Use immediate posting for time-sensitive content

## Checking Status

### View Scheduled Posts

```bash
# In Rails console
bundle exec rails console
```

```ruby
# See all draft (scheduled) posts
Scheduling::Post
  .where(status: 'draft')
  .where.not(optimal_time_calculated: nil)
  .order(:optimal_time_calculated)
  .each do |post|
    puts "#{post.optimal_time_calculated.strftime('%Y-%m-%d %H:%M')} - #{post.photo.path}"
  end
```

### View Cron Logs

```bash
# Last 50 lines
tail -n 50 /home/tim/source/activity/fluffy-train/log/scheduled_posting.log

# Follow in real-time
tail -f /home/tim/source/activity/fluffy-train/log/scheduled_posting.log
```

### Check Next Run Time

```bash
# View scheduled posts
bundle exec rails scheduling:post_scheduled
```

This will show when the next post is scheduled if there are no current posts to publish.

## Advanced Usage

### Schedule Multiple Posts

```bash
# Schedule 3 posts for the next few days
for i in {1..3}; do
  bundle exec rails scheduling:create_scheduled_post[sarah]
  sleep 2
done
```

### Cancel Scheduled Posts

```ruby
# In Rails console
post = Scheduling::Post.find(POST_ID)

# Delete it
post.destroy

# Or post it immediately
Scheduling::SchedulePost.call(post: post)
```

### Reschedule a Post

```ruby
# In Rails console
post = Scheduling::Post.find(POST_ID)

# Change the scheduled time
post.update!(optimal_time_calculated: 2.hours.from_now)
```

## Troubleshooting

### Posts Not Being Posted

**Check if scheduled posts exist:**
```bash
bundle exec rails scheduling:post_scheduled
```

**Check cron is running:**
```bash
# Check system cron service
sudo systemctl status cron

# Or for older systems
sudo service cron status
```

**Check cron logs:**
```bash
grep CRON /var/log/syslog | tail -20
```

**Check application logs:**
```bash
tail -f /home/tim/source/activity/fluffy-train/log/scheduled_posting.log
tail -f /home/tim/source/activity/fluffy-train/log/production.log
```

### Ruby Version Issues

The script automatically loads RVM and uses Ruby 3.4.5. If you see Ruby version errors:

```bash
# Verify RVM is installed
rvm -v

# Verify Ruby 3.4.5 is installed
rvm list

# Install if needed
rvm install 3.4.5
```

### Permission Issues

Make sure the script is executable:

```bash
chmod +x /home/tim/source/activity/fluffy-train/bin/scheduled_posting.sh
```

### Test Cron Job Manually

Run the cron command manually to see any errors:

```bash
/home/tim/source/activity/fluffy-train/bin/scheduled_posting.sh
```

## Configuration

### Adjust Scheduling Window

By default, posts scheduled within the last hour will be posted. To adjust:

Edit `packs/scheduling/lib/tasks/scheduled_posting.rake` and change:

```ruby
one_hour_ago = 1.hour.ago  # Change to 30.minutes.ago for tighter window
```

### Change Cron Frequency

More frequent checks = posts closer to optimal time, but more overhead:

```cron
# Every 15 minutes (very precise)
*/15 * * * * /home/tim/source/activity/fluffy-train/bin/scheduled_posting.sh

# Every 30 minutes (balanced)
*/30 * * * * /home/tim/source/activity/fluffy-train/bin/scheduled_posting.sh

# Every hour (less precise but sufficient)
0 * * * * /home/tim/source/activity/fluffy-train/bin/scheduled_posting.sh
```

## Benefits of This Approach

✅ **Uses Optimal Times** - Posts at calculated optimal times (not just fixed time)
✅ **Simple** - No background worker processes needed
✅ **Reliable** - Cron is built into Linux
✅ **Visible** - Easy to check logs and status
✅ **Flexible** - Can schedule multiple posts in advance
✅ **Safe** - Draft posts can be reviewed before they go out

## Next Steps

1. Test the script manually
2. Create a test scheduled post
3. Verify it posts correctly
4. Set up cron
5. Monitor logs for first few runs
6. Gradually transition to scheduled posting workflow

## Related Documentation

- [Daily Posting Guide](./daily-posting-guide.md) - Overall posting workflows
- [Content Strategy](./04c-content-strategy-engine.md) - Strategy configuration
- [Adding New Photos](./adding-new-photos.md) - Import and prepare content
