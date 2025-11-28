@echo off
REM Ansible-playbook wrapper for Windows using Docker

docker run --rm -it ^
  -v "%cd%:/ansible" ^
  -v "%USERPROFILE%\.ssh:/root/.ssh:ro" ^
  -w /ansible ^
  cytopia/ansible:latest-tools ^
  ansible-playbook %*
