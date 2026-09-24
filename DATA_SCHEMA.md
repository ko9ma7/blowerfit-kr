# BlowerFit KR Data Schema

## Manufacturer

```json
{
  "id": "mfr_...",
  "name": "제조사명",
  "brand_names": ["브랜드"],
  "country": "Korea",
  "korea_class": "domestic_manufacturer",
  "website": "https://...",
  "product_types": ["ring_blower"],
  "purchase_status": "manufacturer_direct_verified",
  "coverage_level": "model_verified",
  "verified_at": "YYYY-MM-DD"
}
```

## Model

제품명 자체와 주파수/전압/출력별 variant를 분리합니다.

```json
{
  "id": "mdl_...",
  "manufacturer_id": "mfr_...",
  "brand": "HRB",
  "series": "HRB Ring Blower",
  "model_name": "HRB-1202MP",
  "blower_type_raw": "ring blower",
  "stage": 2,
  "legacy": false,
  "data_quality": "catalog_spec",
  "application_tags": ["pressure", "vacuum", "blowoff"]
}
```

## Variant

```json
{
  "id": "var_...",
  "model_id": "mdl_...",
  "frequency_hz": 60,
  "phase": 3,
  "voltage_v": 380,
  "motor_kw": 17.3,
  "motor_hp": 23.0,
  "max_airflow_m3_min": 11.0,
  "discharge_pressure_kpa": 70.61,
  "vacuum_kpa": 47.07,
  "sound_dba": 82,
  "weight_kg": 280,
  "efficiency_class": "IE3",
  "needs_curve_verification": true,
  "source_id": "src_..."
}
```

## Supplier

```json
{
  "id": "sup_...",
  "name": "공급처",
  "supplier_type": "official_korea_office",
  "manufacturer_id": "mfr_...",
  "region": "경기",
  "phone": "...",
  "email": "...",
  "website": "https://...",
  "relationship_status": "official_korea_office",
  "quote_mode": "RFQ_or_contact",
  "verified_at": "YYYY-MM-DD"
}
```

## 향후 P-Q Curve 구조

모델 endpoint와 별도로 곡선 좌표를 저장합니다.

```json
{
  "variant_id": "var_...",
  "curve_kind": "pressure",
  "reference_conditions": {
    "temperature_c": 20,
    "pressure_bara": 1.013,
    "frequency_hz": 60
  },
  "data_quality": "official_current_catalog",
  "points": [
    {"airflow_m3_min": 0, "pressure_kpa": 60},
    {"airflow_m3_min": 5, "pressure_kpa": 45},
    {"airflow_m3_min": 10, "pressure_kpa": 5}
  ]
}
```

곡선 좌표가 공식 표가 아니라 이미지 digitization 결과인 경우 반드시 `curve_digitized_approx`로 표시하고 원본 페이지/조건을 함께 저장해야 합니다.

## 검색 facet

- blower type
- application
- manufacturer / brand
- country / Korea availability
- motor kW / HP
- airflow
- pressure / vacuum
- 50/60 Hz
- voltage / phase
- oil-free
- noise
- efficiency
- VFD compatibility
- weight / dimensions
- supplier region
- quote availability
- data quality

## 업데이트 원칙

- 동일 모델의 50/60 Hz를 한 레코드에 덮어쓰지 않습니다.
- 단위 변환값과 원본 단위를 모두 보존합니다.
- 현행/구형 모델 상태를 분리합니다.
- 가격·재고·납기는 `checked_at`이 있는 별도 offer 데이터로 관리합니다.
- 소스가 바뀌면 기존 값을 삭제하기보다 버전/출처 이력을 남깁니다.
