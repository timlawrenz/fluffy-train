---
tags:
  - MOC/project
  - instagram
  - social-media
  - image-generation
  - image-embeddings
  - text-to-image
  - image-editing
status: active
aliases:
project: fluffy-train
---

# 🚀 Project: Untitled

> [!info] Project README
> This is the central hub for the **Untitled** project.
> (Add your goals, key links, and overall mission statement here.)

---

## ✅ Core Documents & Milestones

```dataview
TABLE status, file.mday as "Last Modified"
FROM !"templates"
WHERE project = this.project
SORT file.mtime DESC
```

## 📚 Related Research & Supporting Notes

These are notes that are not core to the project but are related by shared tags. This is useful for finding inspiration and relevant research.

```dataview
LIST 
FROM !"templates"
WHERE contains(file.tags, this.tags) AND !project AND file.name != this.file.name
SORT file.mtime DESC
LIMIT 10
```

## 📝 Open Tasks

```tasks
TASK
FROM !"templates"
WHERE contains(outlinks, this.file.link) AND !completed
GROUP BY file.link
```