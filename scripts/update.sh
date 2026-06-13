#!/usr/bin/env bash
#
# 로또 데이터 자동 갱신 스크립트 (GitHub Actions에서 실행).
# 1) 동행복권 공식에서 다음 회차들을 시도 (CI는 해외라 차단될 수 있음).
# 2) 막히면 smok95 미러 all.json으로 폴백.
# 결과를 all.json(전체) / latest.json(최신 1건)에 기록한다.
#
set -euo pipefail

ALL="all.json"
MIRROR="https://smok95.github.io/lotto/results/all.json"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# 현재 보유한 최대 회차
if [[ -f "$ALL" ]]; then
  CUR=$(jq '[.[].draw_no] | max // 0' "$ALL")
else
  echo "[]" > "$ALL"
  CUR=0
fi
echo "현재 최대 회차: $CUR"

TMP="$(mktemp)"
cp "$ALL" "$TMP"
ADDED=0

# 1) 동행복권 공식 시도 (다음 회차부터 최대 5개)
NEXT=$((CUR + 1))
for i in 0 1 2 3 4; do
  R=$((NEXT + i))
  RESP="$(curl -s -m 15 -A "$UA" \
    "https://www.dhlottery.co.kr/common.do?method=getLottoNumber&drwNo=$R" || true)"
  if echo "$RESP" | jq -e '.returnValue=="success"' >/dev/null 2>&1; then
    ENTRY="$(echo "$RESP" | jq -c '{
      draw_no: .drwNo,
      numbers: [.drwtNo1, .drwtNo2, .drwtNo3, .drwtNo4, .drwtNo5, .drwtNo6],
      bonus_no: .bnusNo,
      date: (.drwNoDate + "T00:00:00Z"),
      divisions: [{prize: .firstWinamnt, winners: .firstPrzwnerCo}],
      total_sales_amount: .totSellamnt
    }')"
    jq --argjson e "$ENTRY" '. += [$e]' "$TMP" > "$TMP.2" && mv "$TMP.2" "$TMP"
    ADDED=$((ADDED + 1))
    echo "동행복권에서 $R 회차 추가"
  else
    break
  fi
done

# 2) 동행복권에서 못 받았으면 미러로 폴백
if [[ "$ADDED" -eq 0 ]]; then
  echo "동행복권 접근 불가 → 미러 폴백 시도"
  MJSON="$(curl -s -m 30 "$MIRROR" || true)"
  if echo "$MJSON" | jq -e 'type=="array"' >/dev/null 2>&1; then
    MMAX=$(echo "$MJSON" | jq '[.[].draw_no] | max // 0')
    echo "미러 최대 회차: $MMAX"
    if [[ "$MMAX" -gt "$CUR" ]]; then
      echo "$MJSON" > "$TMP"
      echo "미러 all.json 채택 (최대 $MMAX)"
    fi
  fi
fi

# 회차 기준 중복 제거 + 오름차순 정렬 후 기록
jq 'unique_by(.draw_no) | sort_by(.draw_no)' "$TMP" > "$ALL"
# 최신 1건
jq 'sort_by(.draw_no) | last' "$ALL" > latest.json

NEWMAX=$(jq '[.[].draw_no] | max // 0' "$ALL")
echo "갱신 후 최대 회차: $NEWMAX"
