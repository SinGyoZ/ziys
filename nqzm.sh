#!/bin/bash

# 检查是否安装了 FFmpeg
if ! command -v ffmpeg &>/dev/null; then
    echo "FFmpeg 未安装，请先安装 FFmpeg！"
    exit 1
fi

# 输入和输出目录
INPUT_DIR="./"  # 默认当前目录
OUTPUT_DIR="./output"  # 输出目录

# 创建输出目录（如果不存在）
mkdir -p "$OUTPUT_DIR"

# 遍历当前目录下的所有 .mkv 文件
for video in *.mkv; do
    # 获取不带扩展名的文件名
    basename="${video%.mkv}"
    
    # 找到对应的 SRT 文件
    subtitle="${basename}.srt"

    if [[ -f "$subtitle" ]]; then
        echo "正在处理视频: $video 和字幕: $subtitle"
        
        # 输出文件路径
        output_file="$OUTPUT_DIR/${basename}_embedded.mkv"

        # 调用 FFmpeg 内嵌硬字幕
        ffmpeg -i "$video" -vf subtitles="$subtitle" -c:a copy "$output_file" -y

        if [[ $? -eq 0 ]]; then
            echo "已生成文件: $output_file"

            # 删除原始视频和字幕文件
            rm -f "$video" "$subtitle"
            echo "已删除原始文件: $video 和 $subtitle"
        else
            echo "处理 $video 时出错，保留原文件。"
        fi
    else
        echo "未找到对应的字幕文件: $subtitle，跳过 $video"
    fi
done

echo "处理完成！所有文件已输出到 $OUTPUT_DIR"
