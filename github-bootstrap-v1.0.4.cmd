@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

rem ============================================================
rem BlowerFit KR - GitHub one-click bootstrap v1.0.3
rem Flow intentionally follows the user's proven bootstrap style.
rem ============================================================
set "REPO_NAME=blowerfit-kr"
set "REPO_VISIBILITY=public"
set "REPO_DESCRIPTION=Industrial blower sizing, duct sizing, selection and RFQ engineering web service"
set "REPO_TOPICS=github-pages,blower,engineering-calculator,air-knife,ring-blower,turbo-blower,pwa,korean"
set "DEFAULT_BRANCH=main"
set "INITIAL_TAG=v1.0.3"
set "INITIAL_COMMIT=feat: initialize BlowerFit KR"
set "UPDATE_COMMIT=chore: update BlowerFit KR"
set "OPEN_AFTER_DEPLOY=1"
rem ============================================================

set "DEPLOY_OK=0"

echo.
echo ============================================================
echo  BlowerFit KR - GitHub Bootstrap v1.0.4
echo ============================================================
echo  Project: %CD%
echo.

if not exist "package.json" (
  echo [ERROR] package.json was not found.
  echo         Run this CMD from the BlowerFit project root.
  goto :fatal
)
if not exist ".github\workflows\deploy.yml" (
  echo [ERROR] .github\workflows\deploy.yml was not found.
  goto :fatal
)

call :check_tool git Git.Git "Git"
if errorlevel 1 goto :fatal
call :check_tool node OpenJS.NodeJS.LTS "Node.js LTS"
if errorlevel 1 goto :fatal
call :check_tool npm OpenJS.NodeJS.LTS "npm"
if errorlevel 1 goto :fatal
call :check_tool gh GitHub.cli "GitHub CLI"
if errorlevel 1 goto :fatal

echo.
echo [CHECK] Node.js 20+
for /f %%V in ('node -p "Number(process.versions.node.split('.')[0])"') do set "NODE_MAJOR=%%V"
if not defined NODE_MAJOR (
  echo [ERROR] Could not read Node.js version.
  goto :fatal
)
if !NODE_MAJOR! LSS 20 (
  echo [ERROR] Node.js 20 or newer is required.
  node --version
  goto :fatal
)
echo [OK] Node.js
node --version

echo.
echo [CHECK] Local dependency / tests / Windows-safe build
call npm ci
if errorlevel 1 (
  echo [ERROR] npm ci failed.
  goto :fatal
)
call npm test
if errorlevel 1 (
  echo [ERROR] Tests failed. GitHub upload stopped.
  goto :fatal
)
call npm run build
if errorlevel 1 (
  echo [ERROR] Build failed. GitHub upload stopped.
  goto :fatal
)
if not exist "dist\index.html" (
  echo [ERROR] Build finished but dist\index.html is missing.
  goto :fatal
)
echo [OK] Tests and build passed.

echo.
echo [CHECK] GitHub authentication
gh auth status >nul 2>&1
if errorlevel 1 (
  echo [INFO] Starting GitHub browser login...
  gh auth login --web --git-protocol https
  if errorlevel 1 (
    echo [ERROR] GitHub login failed.
    goto :fatal
  )
)
gh auth setup-git >nul 2>&1
for /f "usebackq delims=" %%U in (`gh api user --jq .login 2^>nul`) do set "GH_OWNER=%%U"
if not defined GH_OWNER (
  echo [ERROR] Could not determine GitHub username.
  goto :fatal
)
set "FULL_REPO=!GH_OWNER!/%REPO_NAME%"
set "REPO_URL=https://github.com/!FULL_REPO!"
set "REMOTE_URL=https://github.com/!FULL_REPO!.git"
set "PAGES_URL=https://!GH_OWNER!.github.io/%REPO_NAME%/"
if /i "%REPO_NAME%"=="!GH_OWNER!.github.io" set "PAGES_URL=https://!GH_OWNER!.github.io/"
set "ACTIONS_URL=!REPO_URL!/actions/workflows/deploy.yml"
set "SETTINGS_URL=!REPO_URL!/settings"
echo [OK] GitHub user: !GH_OWNER!
echo [OK] Repository : !FULL_REPO!
echo [OK] Pages URL  : !PAGES_URL!

echo.
echo [CHECK] Git repository
if not exist ".git" (
  git init
  if errorlevel 1 goto :git_error
  echo [OK] git init
) else (
  echo [OK] Existing .git directory
)
git branch -M "%DEFAULT_BRANCH%" >nul 2>&1

for /f "delims=" %%N in ('git config user.name 2^>nul') do set "GIT_USER_NAME=%%N"
if not defined GIT_USER_NAME (
  git config user.name "!GH_OWNER!"
  echo [WARN] Git user.name set locally to !GH_OWNER!
)
for /f "delims=" %%E in ('git config user.email 2^>nul') do set "GIT_USER_EMAIL=%%E"
if not defined GIT_USER_EMAIL (
  git config user.email "!GH_OWNER!@users.noreply.github.com"
  echo [WARN] Git user.email set locally to GitHub noreply address.
)

echo.
echo [CHECK] GitHub Repository
gh repo view "!FULL_REPO!" >nul 2>&1
if errorlevel 1 (
  if /i "%REPO_VISIBILITY%"=="private" (
    set "VIS_FLAG=--private"
  ) else if /i "%REPO_VISIBILITY%"=="internal" (
    set "VIS_FLAG=--internal"
  ) else (
    set "VIS_FLAG=--public"
  )
  echo [CHECK] Creating !FULL_REPO!
  gh repo create "!FULL_REPO!" !VIS_FLAG! --description "%REPO_DESCRIPTION%"
  if errorlevel 1 (
    echo [ERROR] Repository creation failed.
    goto :fatal
  )
  echo [OK] Repository created.
) else (
  echo [OK] Existing Repository will be used.
)

echo.
echo [CHECK] origin remote
set "CURRENT_ORIGIN="
for /f "delims=" %%R in ('git remote get-url origin 2^>nul') do set "CURRENT_ORIGIN=%%R"
if not defined CURRENT_ORIGIN (
  git remote add origin "!REMOTE_URL!"
  if errorlevel 1 goto :git_error
  echo [OK] origin added.
) else (
  if /i not "!CURRENT_ORIGIN!"=="!REMOTE_URL!" (
    echo [WARN] Replacing existing origin:
    echo        old: !CURRENT_ORIGIN!
    echo        new: !REMOTE_URL!
    git remote set-url origin "!REMOTE_URL!"
    if errorlevel 1 goto :git_error
  ) else (
    echo [OK] origin is correct.
  )
)

echo.
echo [CHECK] Synchronize existing remote branch
set "REMOTE_MAIN_EXISTS=0"
git ls-remote --exit-code --heads origin "refs/heads/%DEFAULT_BRANCH%" >nul 2>&1
if not errorlevel 1 set "REMOTE_MAIN_EXISTS=1"

if "!REMOTE_MAIN_EXISTS!"=="1" (
  echo [INFO] Remote %DEFAULT_BRANCH% exists. Fetching it before creating the update commit.
  git fetch origin "%DEFAULT_BRANCH%" --prune
  if errorlevel 1 (
    echo [ERROR] Could not fetch origin/%DEFAULT_BRANCH%.
    goto :fatal
  )

  git rev-parse --verify HEAD >nul 2>&1
  if errorlevel 1 (
    echo [INFO] Local repository has no commit yet. Using origin/%DEFAULT_BRANCH% as the base.
    git reset --mixed "origin/%DEFAULT_BRANCH%"
    if errorlevel 1 goto :git_error
  ) else (
    git merge-base HEAD "origin/%DEFAULT_BRANCH%" >nul 2>&1
    if errorlevel 1 (
      echo [WARN] Local and remote histories are unrelated.
      echo [INFO] Keeping the current files, but rebasing the local branch onto origin/%DEFAULT_BRANCH%.
      git branch "bootstrap-local-backup" HEAD >nul 2>&1
      git reset --mixed "origin/%DEFAULT_BRANCH%"
      if errorlevel 1 goto :git_error
    ) else (
      git merge-base --is-ancestor "origin/%DEFAULT_BRANCH%" HEAD >nul 2>&1
      if errorlevel 1 (
        echo [INFO] Remote has commits that are not in this extracted folder.
        echo [INFO] Keeping the current files and using origin/%DEFAULT_BRANCH% as the update base.
        git branch "bootstrap-local-backup" HEAD >nul 2>&1
        git reset --mixed "origin/%DEFAULT_BRANCH%"
        if errorlevel 1 goto :git_error
      ) else (
        echo [OK] Local history already contains origin/%DEFAULT_BRANCH%.
      )
    )
  )
  git branch -M "%DEFAULT_BRANCH%" >nul 2>&1
) else (
  echo [OK] Remote %DEFAULT_BRANCH% does not exist yet. Initial push will be used.
)

echo.
echo [CHECK] Commit
git add -A
if errorlevel 1 goto :git_error
git diff --cached --quiet
if errorlevel 1 (
  git rev-parse --verify HEAD >nul 2>&1
  if errorlevel 1 (
    git commit -m "%INITIAL_COMMIT%"
  ) else (
    git commit -m "%UPDATE_COMMIT%"
  )
  if errorlevel 1 goto :git_error
  echo [OK] Commit created.
) else (
  echo [OK] No new changes to commit.
)

echo.
echo [CHECK] Push main branch
git push -u origin "%DEFAULT_BRANCH%"
if errorlevel 1 (
  echo [ERROR] Push failed even after remote synchronization.
  echo [INFO] Run these diagnostics and share the output if it still fails:
  echo        git status
  echo        git log --oneline --decorate -5
  echo        git log --oneline origin/%DEFAULT_BRANCH% -5
  goto :fatal
)
echo [OK] Source uploaded to GitHub.
for /f "delims=" %%S in ('git rev-parse HEAD 2^>nul') do set "HEAD_SHA=%%S"

echo.
echo [CHECK] Repository metadata
gh repo edit "!FULL_REPO!" --description "%REPO_DESCRIPTION%" --homepage "!PAGES_URL!" --default-branch "%DEFAULT_BRANCH%" --enable-issues --enable-wiki=false --enable-projects=false >nul 2>&1
for %%T in (%REPO_TOPICS:,= %) do gh repo edit "!FULL_REPO!" --add-topic "%%T" >nul 2>&1

echo.
echo [CHECK] GitHub Pages = GitHub Actions
gh api -H "Accept: application/vnd.github+json" "repos/!FULL_REPO!/pages" >nul 2>&1
if errorlevel 1 (
  gh api --method POST -H "Accept: application/vnd.github+json" "repos/!FULL_REPO!/pages" -f build_type=workflow >nul 2>&1
  if errorlevel 1 (
    echo [WARN] Automatic Pages enablement failed.
    echo        Open: !SETTINGS_URL!/pages
  ) else (
    echo [OK] GitHub Pages enabled.
  )
) else (
  gh api --method PUT -H "Accept: application/vnd.github+json" "repos/!FULL_REPO!/pages" -f build_type=workflow >nul 2>&1
  if errorlevel 1 echo [WARN] Pages build_type update failed.
)

echo.
echo [CHECK] Deploy workflow
set "WORKFLOW_READY=0"
for /L %%I in (1,1,10) do (
  if "!WORKFLOW_READY!"=="0" (
    gh workflow view deploy.yml -R "!FULL_REPO!" >nul 2>&1
    if not errorlevel 1 set "WORKFLOW_READY=1"
    if "!WORKFLOW_READY!"=="0" timeout /t 2 /nobreak >nul
  )
)
if "!WORKFLOW_READY!"=="1" (
  gh workflow enable deploy.yml -R "!FULL_REPO!" >nul 2>&1
  gh workflow run deploy.yml --ref "%DEFAULT_BRANCH%" -R "!FULL_REPO!" >nul 2>&1
  set "RUN_ID="
  for /L %%W in (1,1,12) do (
    if not defined RUN_ID (
      timeout /t 2 /nobreak >nul
      for /f "usebackq delims=" %%I in (`gh run list -R "!FULL_REPO!" --workflow deploy.yml --branch "%DEFAULT_BRANCH%" --limit 1 --json databaseId --jq ".[0].databaseId" 2^>nul`) do set "RUN_ID=%%I"
    )
  )
  if defined RUN_ID (
    echo [CHECK] Watching Actions run !RUN_ID!
    gh run watch !RUN_ID! -R "!FULL_REPO!" --compact --exit-status
    if errorlevel 1 (
      echo [ERROR] GitHub Actions deployment failed.
      echo         !ACTIONS_URL!
      goto :fatal
    ) else (
      set "DEPLOY_OK=1"
      echo [OK] GitHub Pages deployment succeeded.
    )
  ) else (
    echo [WARN] Could not identify the Actions run yet.
    echo        Check: !ACTIONS_URL!
  )
) else (
  echo [WARN] deploy.yml is not visible on GitHub yet.
  echo        Check: !ACTIONS_URL!
)

if "!DEPLOY_OK!"=="1" (
  echo.
  echo [CHECK] Tag / Release
  git ls-remote --exit-code --tags origin "refs/tags/%INITIAL_TAG%" >nul 2>&1
  if errorlevel 1 (
    git tag -a "%INITIAL_TAG%" -m "BlowerFit KR %INITIAL_TAG%"
    if not errorlevel 1 git push origin "%INITIAL_TAG%" >nul 2>&1
  )
  gh release view "%INITIAL_TAG%" -R "!FULL_REPO!" >nul 2>&1
  if errorlevel 1 gh release create "%INITIAL_TAG%" -R "!FULL_REPO!" --title "%INITIAL_TAG% - BlowerFit KR" --notes "Windows build path fix and GitHub Pages bootstrap reliability update." --verify-tag >nul 2>&1
)

echo.
echo ============================================================
echo [OK] Bootstrap finished
echo Repository : !REPO_URL!
echo Pages      : !PAGES_URL!
echo Actions    : !ACTIONS_URL!
echo ============================================================
echo.
if "%OPEN_AFTER_DEPLOY%"=="1" (
  start "" "!PAGES_URL!"
  start "" "!REPO_URL!"
)
pause
exit /b 0

:check_tool
set "TOOL=%~1"
set "WINGET_ID=%~2"
set "DISPLAY=%~3"
echo [CHECK] %DISPLAY%
where %TOOL% >nul 2>&1
if not errorlevel 1 (
  for /f "delims=" %%V in ('%TOOL% --version 2^>nul') do (
    echo [OK] %%V
    goto :eof
  )
  echo [OK] %DISPLAY% installed.
  goto :eof
)
echo [WARN] %DISPLAY% not found.
where winget >nul 2>&1
if errorlevel 1 (
  echo [ERROR] winget is unavailable. Install %DISPLAY% manually and rerun.
  exit /b 1
)
echo [CHECK] Installing %DISPLAY% using winget...
winget install --id %WINGET_ID% -e --source winget --accept-source-agreements --accept-package-agreements
if errorlevel 1 (
  echo [ERROR] Automatic installation failed.
  exit /b 1
)
echo [WARN] Installation completed. Close this CMD window and run it again so PATH refreshes.
exit /b 1

:git_error
echo [ERROR] Git command failed. Check: git status and git remote -v
goto :fatal

:fatal
echo.
echo ============================================================
echo [ERROR] Bootstrap did not complete.
echo Fix the error above and rerun github-bootstrap.cmd.
echo ============================================================
pause
exit /b 1
