# Import & Schedule Thanksgiving Post #1

**Due**: Monday, November 11, 2024 at 9:00am ET  
**Time Remaining**: ~2.5 days  
**Status**: Photo ready, needs import & scheduling

---

## Quick Import (Option 1: Use Script)

```bash
# Run the helper script
PHOTO_PATH=/path/to/your/thanksgiving-photo.jpg \
  bin/rails runner scripts/import_thanksgiving_nov11.rb
```

This will:
- ✅ Import photo to Sarah
- ✅ Create "Thanksgiving Morning Coffee Nov 2024" cluster
- ✅ Assign photo to cluster
- ✅ Tag with "Seasonal & Events" pillar
- ✅ Ready for scheduling

---

## Manual Import (Option 2: Step by Step)

### Step 1: Import Photo
```bash
# Place your photo somewhere accessible
# Example: ~/thanksgiving-content/morning-coffee.jpg

# Import to Sarah
rake photos:import PERSONA=sarah PATH=~/thanksgiving-content/morning-coffee.jpg

# Verify
rake photos:list PERSONA=sarah | tail -5
```

### Step 2: Create Cluster & Assign
```bash
# Open Rails console
bin/rails console

# Run this:
persona = Persona.find_by(name: 'sarah')

cluster = Clustering::Cluster.create!(
  persona: persona,
  name: 'Thanksgiving Morning Coffee Nov 2024',
  pillar_name: 'Seasonal & Events',
  size: 0
)

photo = persona.photos.order(created_at: :desc).first
photo.update!(cluster: cluster)
cluster.increment!(:size)

puts "✅ Photo #{photo.id} → Cluster '#{cluster.name}'"
exit
```

### Step 3: Schedule the Post
```bash
# Use existing scheduling system
rake content_strategy:schedule_next PERSONA=sarah DATE="2024-11-11 09:00:00 EST"

# OR manual scheduling (TBD based on your system)
```

---

## Post Details

**Photo**: Comfy at home with coffee mug, oversized hoodie, autumn tones

**Caption**:
```
Something about these slower November mornings ☕ The way the light hits differently this time of year
```

**Hashtags** (10):
```
#MorningLight #CoffeeTime #AutumnVibes #SlowLiving #NovemberMood 
#CozyMornings #UrbanStyle #EverydayMoments #LifestylePhotography #SimpleBeauty
```

**Scheduled Time**: Monday, November 11, 2024 at 9:00am ET

**Pillar**: Seasonal & Events (5%)  
**Cluster**: Thanksgiving Morning Coffee Nov 2024

---

## Verification Checklist

Before scheduling, verify:

- [ ] Photo imported successfully
- [ ] Photo has embeddings generated
- [ ] Photo has photo_analysis completed
- [ ] Photo assigned to correct cluster
- [ ] Caption matches Sarah's voice
- [ ] Hashtags are relevant
- [ ] Scheduled time is correct (9am ET Monday)
- [ ] No conflicts with other scheduled posts

---

## Next Steps After Nov 11 Post

**Post #2 - Thursday, Nov 14, 11am ET**
- Theme: Urban Gratitude
- Photo needed: Neighborhood spot, fall colors
- Caption: "Found myself grateful for these familiar corners..."

**Post #3 - Monday, Nov 18, 9am ET**
- Theme: Simple Pleasures
- Photo needed: Cozy home (candle/book/blanket)
- Caption: "Pause and grateful..."

Start creating Post #2 photos in background!

---

**Status**: Ready to import  
**Urgency**: HIGH - Import by Saturday Nov 9  
**Schedule**: By Sunday Nov 10 at latest
