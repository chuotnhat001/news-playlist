# News Playlist

## Vision
Bien trai nghiem doc bao roi rac thanh trai nghiem nghe lien tuc — mot lan bam Play, nghe playlist tin tuc tu dong khi lai xe.

## Problem
Nguoi dung Viet Nam nghe tin tuc audio tren bao (Dan Tri, Soha) phai mo tung bai, bam play tung bai, chon bai tiep theo thu cong. Mat tap trung va khong an toan khi lai xe.

## Solution
Flutter mobile app (iOS + Android) tu dong crawl audio tu bao, tao playlist theo chuyen muc, phat lien tuc voi background playback.

## Target User
Nguoi Viet Nam doc bao hang ngay, thuong xuyen lai xe/di chuyen, da quen nghe audio tren cac trang bao.

## Tech Stack
- Flutter 3.x (Dart)
- Riverpod (state management)
- just_audio + audio_service (background playback)
- SQLite/sqflite (local cache)
- dio + html package (HTTP + HTML parsing)
- GitHub Actions (CI/CD)
- Shorebird (OTA updates)

## Architecture
Client-only — app tu crawl + cache local. Khong co backend rieng.

## Key Decisions
- Client crawl + SQLite cache (TTL 6h) thay vi backend rieng
- Background Dart Isolate cho crawl (khong block UI)
- Single AudioPlayerProvider (Riverpod) cho state management
- Feature-first folder structure

## Constraints
- Chi aggregate audio co san (khong TTS)
- Phu thuoc bao duy tri tinh nang audio
- Rui ro phap ly: crawl khong co thoa thuan
- Solo developer

## Status
- Stage: Pre-development
- Design doc: APPROVED (2026-06-20)
- Eng review: Completed
- Blocking: Spike crawl feasibility + legal review

## Links
- Design doc: ~/.gstack/projects/NewsPlaylist/Admin-unknown-design-20260620-011755.md
- Idea doc: Y-Tuong.txt
