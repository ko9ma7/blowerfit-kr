import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { buildCandidates, productRows } from '../web/selection.js'
import { defaultProject, calculateProject } from '../web/calculations.js'

const DATA = JSON.parse(await readFile(new URL('../web/data/blower_webservice_seed.json', import.meta.url), 'utf8'))

test('seed data contains manufacturers, variants and suppliers', () => {
  assert.ok(DATA.manufacturers.length >= 20)
  assert.ok(DATA.variants.length >= 70)
  assert.ok(DATA.suppliers.length >= 10)
})

test('candidate builder returns scored candidates without inventing curve verification', () => {
  const p = defaultProject()
  p.tab = 'flow'
  p.flow.requiredFlowM3Min = 8
  p.flow.terminalPressureKpa = 10
  const calc = calculateProject(p)
  const rows = buildCandidates(DATA, calc, p)
  assert.ok(rows.length > 0)
  assert.ok(rows.every(r => typeof r.score === 'number'))
  assert.ok(rows.some(r => r.curveStatus === 'curve_required' || r.curveStatus === 'verified'))
})

test('product filters support 60 Hz and Korea availability', () => {
  const rows = productRows(DATA, {
    q:'', type:'', manufacturer:'', minKw:0, maxKw:500,
    minFlow:0, minPressure:0, frequency:60, koreaOnly:true
  })
  assert.ok(rows.length > 0)
  assert.ok(rows.every(r => r.variant.frequency_hz == null || Number(r.variant.frequency_hz) === 60))
})
