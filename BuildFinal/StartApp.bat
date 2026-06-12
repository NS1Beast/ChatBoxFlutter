@echo off
chcp 65001 > nul
title Chat App Launcher

:: Chuyển thư mục làm việc của file .bat về đúng vị trí thư mục BuildFinal
cd /d "%~dp0"

:: Ép file C# chạy ở chế độ Development như lúc gõ code trong VS Code
set ASPNETCORE_ENVIRONMENT=Development

echo ==========================================
echo ĐANG KHỞI ĐỘNG HỆ THỐNG CHAT APP...
echo ==========================================

:: 1. Bật Server C#
echo [1/2] Đang khởi động Backend Server...
if exist "Backend\ChatApp.Api.exe" (
    :: 🎯 ĐÃ SỬA: Thêm /D "Backend" để ép C# đứng đúng vị trí của nó để đọc appsettings.json
    :: 🎯 ĐÃ SỬA: Thay localhost thành 127.0.0.1 để ép chạy IPv4 chống lỗi block mạng Windows
    start "Chat Server" /MIN /D "Backend" "ChatApp.Api.exe" --urls "http://127.0.0.1:5034"
) else (
    echo [LỖI] Không tìm thấy file Backend\ChatApp.Api.exe!
    pause
    exit
)

:: 2. Đợi 3 giây cho server nạp cấu hình và mở cổng Database
echo Đang chờ Server kết nối Database...
timeout /t 3 /nobreak > NUL

:: 3. Bật Giao diện Flutter
echo [2/2] Đang mở ứng dụng Chat...
if exist "FontEnd\chatapp.exe" (
    :: 🎯 ĐÃ SỬA: Thêm /D "FontEnd" để Flutter nạp các file thư viện .dll chạy kèm không bị lỗi đường dẫn
    start "Chat Frontend" /WAIT /D "FontEnd" "chatapp.exe"
) else (
    echo [LỖI] Không tìm thấy file FontEnd\chatapp.exe!
    pause
    exit
)

:: 4. Tắt server chạy ngầm khi người dùng bấm dấu X thoát app Flutter
cd ..
taskkill /IM "ChatApp.Api.exe" /F > NUL 2>&1
exit