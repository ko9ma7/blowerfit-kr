import test from 'node:test'
import assert from 'node:assert/strict'
import {
  airDensityKgM3,
  openingAreaM2,
  equivalentRoundDiameterMm,
  calcAirknife,
  calcDuct,
  defaultProject,
  calculateProject,
} from '../web/calculations.js'

test('20°C near sea level moist-air density is physically plausible', () => {
  const rho = airDensityKgM3({temperatureC:20, altitudeM:0, relativeHumidityPct:50})
  assert.ok(rho > 1.18 && rho < 1.22, `rho=${rho}`)
})

test('opening areas for circle and rectangle are correct', () => {
  const circle = openingAreaM2({shape:'circle', diameterMm:10, widthMm:0, heightMm:0, lengthMm:0})
  assert.ok(Math.abs(circle - Math.PI * 0.01 ** 2 / 4) < 1e-12)
  const rect = openingAreaM2({shape:'rectangle', diameterMm:0, widthMm:20, heightMm:5, lengthMm:0})
  assert.ok(Math.abs(rect - 0.0001) < 1e-12)
})

test('equivalent pipe diameter increases with flow', () => {
  assert.ok(equivalentRoundDiameterMm(20, 20) > equivalentRoundDiameterMm(10, 20))
})

test('doubling air-knife width doubles raw slot airflow', () => {
  const p = defaultProject()
  const r1 = calcAirknife(p.airknife, p.environment)
  const p2 = structuredClone(p.airknife)
  p2.knifeWidthMm *= 2
  const r2 = calcAirknife(p2, p.environment)
  assert.ok(Math.abs(r2.rawFlowM3Min / r1.rawFlowM3Min - 2) < 1e-9)
})

test('duct mode sums branch raw flow', () => {
  const p = defaultProject()
  const r = calcDuct(p.duct, p.environment)
  assert.equal(r.rawFlowM3Min, 8)
  assert.equal(r.branchResults.length, 2)
  assert.ok(r.designPressureKpa > 0)
})

test('default project calculates a valid design', () => {
  const p = defaultProject()
  const r = calculateProject(p)
  assert.equal(r.valid, true)
  assert.ok(r.designFlowM3Min > 0)
  assert.ok(r.designPressureKpa > 0)
  assert.ok(r.selectedMainStandardDiameterMm > 0)
  assert.ok(r.formulas.length >= 5)
})
