#!/bin/bash

# ==========================================
# SIA Booking Service - Auto Healing Pipeline
# ==========================================

echo "🚀 Bắt đầu chạy Maven Build..."
mvn clean install > build_log.txt 2>&1
BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ BUILD SUCCESS! Không cần AI can thiệp."
    exit 0
fi

echo "❌ BUILD FAILED! Kích hoạt The Watcher..."

# Tạo một Session ID duy nhất dựa trên thời gian (Unix Timestamp)
# Việc này ĐẢM BẢO Agent không nhớ bất kỳ rác nào từ lần chạy trước
WATCHER_SESSION="watcher-$(date +%s)"

# Bước 1: Gọi Agent đọc Log
ERROR_SUMMARY=$(openclaw agent \
  --session-id "$WATCHER_SESSION" \
  -m "Read build_log.txt. Find the compilation error. Output ONLY a valid JSON string like this: {\"file\": \"src/.../BookingService.java\", \"error\": \"cannot find symbol method...\"}. Do NOT output any markdown blocks or explanations.")

# Tách chuỗi JSON (bỏ qua các ký tự thừa nếu AI lỡ nói nhiều)
FILE_TO_FIX=$(echo "$ERROR_SUMMARY" | grep -o '{"file".*' | jq -r '.file')
ERROR_MSG=$(echo "$ERROR_SUMMARY" | grep -o '{"file".*' | jq -r '.error')

if [ "$FILE_TO_FIX" == "null" ] || [ -z "$FILE_TO_FIX" ]; then
    echo "⚠️ Watcher không thể parse JSON. Output gốc từ AI: $ERROR_SUMMARY"
    echo "Cần kiểm tra tay."
    exit 1
fi

echo "🔍 Phát hiện lỗi tại file: $FILE_TO_FIX"
echo "🔧 Kích hoạt The Fixer để vá lỗi..."

# Bước 2: Gọi Agent sửa code bằng một Session riêng biệt khác
FIXER_SESSION="fixer-$(date +%s)"

openclaw agent \
  --session-id "$FIXER_SESSION" \
  -m "You are fixing a compilation error.
  Target File: $FILE_TO_FIX
  Error: $ERROR_MSG

  Read the specific file. Fix the code to resolve the error. Ensure the syntax is completely correct. Do not touch any other files."

echo "♻️ Đã sửa xong! Chạy lại luồng kiểm tra (Đệ quy)..."
./auto-healer.sh
