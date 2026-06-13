#!/usr/bin/env bash
#
# 연금복권720+ 데이터 자동 갱신 (GitHub Actions에서 실행).
# 동행복권 pt720 JSON API는 해외(러너)에서도 접근 가능 → 직접 받아온다(미러 불필요).
# 결과를 pension.json(전체) / pension-latest.json(최신 1건)에 기록한다.
#
set -euo pipefail

OUT="pension.json"
URL="https://www.dhlottery.co.kr/pt720/selectPstPt720WnList.do"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

RAW="$(mktemp)"
curl -s -m 30 -A "$UA" \
  -H "X-Requested-With: XMLHttpRequest" \
  -H "Referer: https://www.dhlottery.co.kr/pt720/result" \
  "$URL" -o "$RAW"

# 응답이 정상 JSON 배열인지 확인 (이상하면 기존 파일 유지하고 종료)
if ! jq -e '.data.result | type=="array"' "$RAW" >/dev/null 2>&1; then
  echo "연금복권 응답 이상 — 갱신 건너뜀"
  exit 0
fi

# pt720 형식 → 우리 형식으로 변환 (1등/보너스는 앞자리 0 보존을 위해 문자열 유지)
#   psltEpsd→round, psltRflYmd→date, wnBndNo→group(조), wnRnkVl→first, bnsRnkVl→bonus
jq -c '[.data.result[] | {
  round: (.psltEpsd | tonumber),
  date:  (.psltRflYmd[0:4] + "-" + .psltRflYmd[4:6] + "-" + .psltRflYmd[6:8]),
  group: (.wnBndNo | tonumber),
  first: (.wnRnkVl | tostring),
  bonus: (.bnsRnkVl | tostring)
}] | unique_by(.round) | sort_by(.round)' "$RAW" > "$OUT"

jq -c 'sort_by(.round) | last' "$OUT" > pension-latest.json

echo "연금복권 갱신 완료: $(jq 'length' "$OUT") 회"
