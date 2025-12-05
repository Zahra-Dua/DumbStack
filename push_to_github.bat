@echo off
cd /d "%~dp0"
echo Initializing git...
git init
echo.
echo Adding remote...
git remote remove origin 2>nul
git remote add origin https://github.com/Zahra-Dua/DumbStack.git
echo.
echo Adding all files...
git add .
echo.
echo Committing...
git commit -m "Initial commit: Parental Control App"
echo.
echo Setting branch to main...
git branch -M main
echo.
echo Pushing to GitHub...
git push -u origin main
echo.
echo Done! Check https://github.com/Zahra-Dua/DumbStack
pause

