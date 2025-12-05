# GitHub Push Commands - Zahra-Dua

## Step 1: Git Initialize (agar pehle se initialized nahi hai)
```powershell
git init
```

## Step 2: GitHub Repository Create Karein
1. GitHub.com par jao
2. Login karo (Zahra-Dua account se)
3. New Repository create karo
4. Repository name: `parental-control-app` (ya jo bhi naam chahiye)
5. **Public** ya **Private** select karo
6. **Initialize with README** mat check karo (agar already code hai)
7. Create repository button click karo

## Step 3: Remote Add Karein
```powershell
git remote add origin https://github.com/Zahra-Dua/parental-control-app.git
```
**Note:** `parental-control-app` ko apni repository name se replace karein

## Step 4: All Files Add Karein
```powershell
git add .
```

## Step 5: Commit Karein
```powershell
git commit -m "Initial commit: Parental Control App with URL tracking and app limits"
```

## Step 6: Branch Set Karein (agar pehli baar)
```powershell
git branch -M main
```

## Step 7: Push Karein
```powershell
git push -u origin main
```

---

## Agar Already Git Initialized Hai:

### Check Status:
```powershell
git status
```

### Remote Check:
```powershell
git remote -v
```

### Remote Update (agar already remote hai):
```powershell
git remote set-url origin https://github.com/Zahra-Dua/parental-control-app.git
```

### Push:
```powershell
git add .
git commit -m "Update: Fixed Kotlin compilation errors and URL tracking"
git push -u origin main
```

---

## Complete One-Liner Commands:

### First Time Push:
```powershell
git init
git remote add origin https://github.com/Zahra-Dua/parental-control-app.git
git add .
git commit -m "Initial commit: Parental Control App"
git branch -M main
git push -u origin main
```

### Update Existing Repository:
```powershell
git add .
git commit -m "Update: Latest changes"
git push origin main
```

---

## Important Notes:
1. **GitHub Username/Password:** Agar 2FA enabled hai, to Personal Access Token use karein
2. **Repository Name:** GitHub par jo repository name banaya hai, wahi use karein
3. **Branch Name:** `main` ya `master` - GitHub par check karein

## Personal Access Token (agar password kaam na kare):
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. Permissions: `repo` select karo
4. Token copy karo aur password ki jagah use karo

