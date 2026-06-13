# lotto-data

로또 6/45 회차별 추첨결과를 JSON으로 제공하는 데이터 저장소입니다.
LottoPick 앱이 사용하며, 매주 토요일 [GitHub Actions](.github/workflows/update.yml)로 자동 갱신됩니다.

> 데이터에 오류가 있을 수 있습니다. 정확한 당첨번호는 [동행복권](https://www.dhlottery.co.kr) 공식 사이트에서 확인하세요.

## 사용 (GitHub Pages)

- 전체 회차: `https://papaya5rhw1984.github.io/lotto-data/all.json`
- 최신 회차: `https://papaya5rhw1984.github.io/lotto-data/latest.json`

## 형식

```json
{
  "draw_no": 1228,
  "numbers": [24, 29, 30, 31, 35, 44],
  "bonus_no": 1,
  "date": "2026-06-13T00:00:00Z",
  "divisions": [
    { "prize": 2698334421, "winners": 11 }
  ],
  "total_sales_amount": 119052273000
}
```

- `divisions[0]` = 1등(1인당 당첨금액 `prize`, 당첨인원 `winners`). 미러 폴백 시에는 2~5등까지 포함될 수 있습니다.
- `all.json` 은 위 객체들의 배열이며 회차 오름차순으로 정렬됩니다.

## 자동 갱신 동작

[`scripts/update.sh`](scripts/update.sh):
1. 동행복권 공식 API로 새 회차를 시도합니다(GitHub 러너는 해외라 차단될 수 있음).
2. 막히면 공개 미러(`smok95/lotto`)의 `all.json`으로 폴백합니다.

미러가 중단되면 `scripts/update.sh` 의 `MIRROR` 값을 다른 출처로 바꾸세요.

## 데이터 출처에 관하여

로또 당첨번호는 공개된 사실(fact) 정보로 저작권 대상이 아닙니다. 본 저장소는 이를
자체적으로 수집·호스팅하며, 갱신 시 공개된 출처를 보조적으로 참조합니다.
