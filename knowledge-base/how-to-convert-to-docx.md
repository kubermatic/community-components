
# How to render the checklist to Word / Google Doc

In Example the check-list

1. Render it by using [pandoc](https://pandoc.org/)
```
pandoc setup-checklist/*.md -o kkp-requirements-checklist.docx
```

2. Create a new googledoc based on a Kubermatic Template:
- Visit: https://docs.google.com/document/u/0/?tgif=d&ftv=1
- Choose `Template Kubermatic Specifiction Doc` in the template gallery

3. Copy paste the converted doc