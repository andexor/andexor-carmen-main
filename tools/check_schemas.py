#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Andexor Network, Inc.
# Author: Ed Jenkins <ed@andexor.net>
"""Load db/carmen/0001_init.sql into an in-memory SQLite database and run
constraint smoke tests. Exit non-zero on any failure. Run from the repo root."""
import pathlib
import sqlite3
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
failures = 0


def expect(con, sql, should_fail, label):
    global failures
    try:
        con.execute(sql)
        failed = False
    except Exception:
        failed = True
    ok = failed == should_fail
    failures += 0 if ok else 1
    print(f"  [{'PASS' if ok else 'FAIL'}] {label}")


def check(label, ok):
    global failures
    failures += 0 if ok else 1
    print(f"  [{'PASS' if ok else 'FAIL'}] {label}")


c = sqlite3.connect(":memory:")
c.execute("PRAGMA foreign_keys=ON")
c.executescript((ROOT / "db" / "carmen" / "0001_init.sql").read_text())
tables = c.execute("select count(*) from sqlite_master where type='table'").fetchone()[0]
trig = c.execute("select count(*) from sqlite_master where type='trigger'").fetchone()[0]
print(f"carmen: loaded, {tables} tables, {trig} triggers")

# Every SRT domain used by a trigger must exist in srt.
used = {r[0].split(" not in ")[1].split("'")[0] for r in c.execute("select sql from sqlite_master where type='trigger'") if " not in " in r[0]}
have = {r[0] for r in c.execute("select distinct domain from srt")}
for d in sorted(used - have):
    failures += 1
    print(f"  [FAIL] trigger domain {d} missing from srt")
for d in sorted(have - used):
    failures += 1
    print(f"  [FAIL] srt domain {d} is not enforced by any trigger")

expect(c, "INSERT INTO company(id) VALUES('c0')", True, "company with neither name nor website rejected")
expect(c, "INSERT INTO company(id,website,domain) VALUES('c1','https://acme.example','acme.example')", False, "company with only a website accepted")
expect(c, "INSERT INTO company(id,name) VALUES('c2','Acme Two')", False, "company with only a name accepted")
expect(c, "INSERT INTO company(id,name,domain) VALUES('c3','Dup','acme.example')", True, "duplicate domain rejected")
expect(c, "INSERT INTO company(id,name) VALUES('C4','Upper')", True, "uppercase id rejected")
expect(c, "UPDATE company SET stage='prospect' WHERE id='c1'", True, "lowercase stage rejected (SRT)")
expect(c, "UPDATE company SET stage='HOT' WHERE id='c1'", True, "unknown stage rejected (SRT)")
expect(c, "UPDATE company SET stage='PROSPECT', fit_score=72, need_score=64, recommendation='REACH_OUT' WHERE id='c1'", False, "PROSPECT with scores accepted")
expect(c, "UPDATE company SET fit_score=101 WHERE id='c1'", True, "score above 100 rejected")
expect(c, "INSERT INTO contact(id,company_id) VALUES('p0','c1')", True, "contact with neither name nor email rejected")
expect(c, "INSERT INTO contact(id,company_id,email,is_primary) VALUES('p1','c1','a@acme.example',1)", False, "contact with only an email accepted")
expect(c, "INSERT INTO contact(id,company_id,name,is_primary) VALUES('p2','c1','Bea',1)", True, "second primary contact rejected")
expect(c, "INSERT INTO deal(id,company_id,name,engagement_model) VALUES('d1','c1','Site rebuild','RETAINER')", False, "deal accepted")
expect(c, "INSERT INTO deal(id,company_id,name,engagement_model) VALUES('d2','c1','X','HOURLY')", True, "unknown engagement model rejected (SRT)")
expect(c, "INSERT INTO agreement(id,company_id,type,status) VALUES('a1','c1','MSA','ACTIVE')", False, "MSA accepted with only company and type")
expect(c, "INSERT INTO agreement(id,company_id,parent_agreement_id,type,engagement_model,amount_cents,amount_period) VALUES('a2','c1','a1','SOW','RETAINER',150000,'MONTHLY')", False, "SOW under the MSA accepted")
expect(c, "INSERT INTO agreement(id,company_id,parent_agreement_id,type) VALUES('a3','c1','a3','SOW')", True, "agreement as its own parent rejected")
expect(c, "DELETE FROM agreement WHERE id='a1'", True, "deleting an MSA that has a SOW rejected")
expect(c, "DELETE FROM company WHERE id='c1'", True, "deleting a company that has agreements rejected")
expect(c, "INSERT INTO rubric_criterion(id,section,prompt) VALUES('r1','NEED','No service')", True, "NEED criterion without a service rejected")
expect(c, "INSERT INTO rubric_criterion(id,section,service_id,prompt) VALUES('r2','FIT','web-hosting','Has service')", True, "FIT criterion with a service rejected")
expect(c, "INSERT INTO rubric_answer(company_id,criterion_id,value,points) VALUES('c1','00000000-0000-4000-8000-000000000101','YES',1.0)", False, "manual answer accepted")
expect(c, "INSERT INTO rubric_answer(company_id,criterion_id,value,points) VALUES('c1','00000000-0000-4000-8000-000000000101','NO',0.0)", True, "second answer in effect for one criterion rejected")
expect(c, "INSERT INTO ai_model(id,provider,model_id,label) VALUES('m1','CLAUDE','x','No job')", True, "model that can neither research nor score rejected")
m1 = "00000000-0000-4000-8000-000000000001"
m2 = "00000000-0000-4000-8000-000000000002"
m3 = "00000000-0000-4000-8000-000000000006"
expect(c, f"INSERT INTO ai_run(id,company_id,kind,ai_model_id) VALUES('run-r1','c1','RESEARCH','{m1}')", False, "research run accepted")
expect(c, f"INSERT INTO ai_run(id,company_id,kind,ai_model_id,input_run_id) VALUES('run-r2','c1','RESEARCH','{m2}','run-r1')", True, "research run with an input run rejected")
for i, m in enumerate((m1, m2, m3)):
    expect(c, f"INSERT INTO ai_run(id,company_id,kind,ai_model_id,input_run_id,fit_score,need_score) VALUES('run-s{i}','c1','SCORING','{m}','run-r1',70,60)", False, f"scoring run {i + 1} of 3 on one dossier accepted")
    expect(c, f"INSERT INTO ai_run_answer(ai_run_id,criterion_id,value,points,probability) VALUES('run-s{i}','00000000-0000-4000-8000-000000000101','YES',1.0,0.9)", False, f"answer for scoring run {i + 1} accepted")
expect(c, "INSERT INTO ai_run_fact(id,ai_run_id,key,value,decision) VALUES('f1','run-r1','cms','WordPress','MAYBE')", True, "unknown fact decision rejected (SRT)")
expect(c, "INSERT INTO app_user(id,email) VALUES('u1','ed@example.com')", False, "first user accepted")
check("first user is ADMIN", c.execute("SELECT role FROM app_user WHERE id='u1'").fetchone()[0] == "ADMIN")
expect(c, "INSERT INTO app_user(id,email) VALUES('u2','b@example.com')", False, "second user accepted")
check("second user defaults to READER", c.execute("SELECT role FROM app_user WHERE id='u2'").fetchone()[0] == "READER")
expect(c, "UPDATE app_user SET role='MEMBER' WHERE id='u2'", False, "READER raised to MEMBER")
expect(c, "UPDATE app_user SET role='OWNER' WHERE id='u2'", True, "unknown role rejected (SRT)")
expect(c, "INSERT INTO company(id,name) VALUES('cp1','Phone Co')", False, "company for phone test accepted")
expect(c, "INSERT INTO contact(id,company_id,name,phone) VALUES('ph1','cp1','A','5551234567')", False, "first contact with a phone accepted")
expect(c, "INSERT INTO contact(id,company_id,name,phone) VALUES('ph2','cp1','B','5551234567')", False, "second contact with the same phone accepted (index not unique)")
check("contact phone index exists and is not unique", (c.execute("SELECT sql FROM sqlite_master WHERE name='contact_phone_idx'").fetchone() or [""])[0].startswith("CREATE INDEX"))
expect(c, f"INSERT INTO ai_run(id,company_id,kind,ai_model_id) VALUES('run-d1','c1','RESEARCH','{m1}')", False, "run for timing test accepted")
check("duration_ms is NULL before the run finishes", c.execute("SELECT duration_ms FROM ai_run WHERE id='run-d1'").fetchone()[0] is None)
expect(c, "UPDATE ai_run SET started_at='2026-11-21T14:03:05.123Z' WHERE id='run-d1'", False, "run started")
expect(c, "UPDATE ai_run SET finished_at='2026-11-21T14:05:19.623Z' WHERE id='run-d1'", False, "run finished")
check("duration_ms is set from the timestamps (134500 ms)", c.execute("SELECT duration_ms FROM ai_run WHERE id='run-d1'").fetchone()[0] == 134500)
expect(c, "UPDATE ai_run SET model_ms=-1 WHERE id='run-d1'", True, "negative model_ms rejected")
expect(c, "INSERT INTO deal(id,company_id,name,created_at) VALUES('dt1','c1','Timing test','2026-11-01T00:00:00.000Z')", False, "deal for timing test accepted")
check("total_deal_time is NULL while the deal is open", c.execute("SELECT total_deal_time FROM deal WHERE id='dt1'").fetchone()[0] is None)
expect(c, "UPDATE deal SET stage='NEGOTIATION' WHERE id='dt1'", False, "deal moved to NEGOTIATION")
check("total_deal_time is still NULL after a non-closing stage", c.execute("SELECT total_deal_time FROM deal WHERE id='dt1'").fetchone()[0] is None)
expect(c, "UPDATE deal SET closed_at='2026-11-03T12:00:00.000Z', stage='WON' WHERE id='dt1'", False, "deal moved to WON")
check("total_deal_time is 216000 s (2.5 days) when WON", c.execute("SELECT total_deal_time FROM deal WHERE id='dt1'").fetchone()[0] == 216000)
expect(c, "INSERT INTO deal(id,company_id,name,created_at) VALUES('dt2','c1','Timing test 2','2026-11-01T00:00:00.000Z')", False, "second deal for timing test accepted")
expect(c, "UPDATE deal SET stage='LOST' WHERE id='dt2'", False, "deal moved to LOST with no closed_at")
check("closed_at is stamped and total_deal_time set when LOST", c.execute("SELECT closed_at IS NOT NULL AND total_deal_time > 0 FROM deal WHERE id='dt2'").fetchone()[0] == 1)
expect(c, "INSERT INTO enrichment_fact(id,company_id,key,value) VALUES('ef1','c1','has_website','YES')", False, "fact with only a key and value accepted")
expect(c, "INSERT INTO enrichment_fact(id,company_id,key,value,notes) VALUES('ef2','c1','website_up_to_date','NO','Last updated 2019; old WordPress theme')", False, "fact with a note accepted")
expect(c, "INSERT INTO company(id,name,source) VALUES('cs1','Expo Co','SBE-2026-ATLANTA')", False, "company with the SBE-2026-ATLANTA lead source accepted")
expect(c, "INSERT INTO task(id,title) VALUES('t1','Call back')", False, "task with only a title accepted")
expect(c, "UPDATE task SET status='DONE' WHERE id='t1'", True, "DONE without completed_at rejected")
expect(c, "INSERT INTO document(id,company_id,agreement_id,file_name,content_type,size_bytes,sha256,r2_key) VALUES('doc1','c1','a1','msa.pdf','application/pdf',10,'ab','c1/doc1')", False, "document accepted")
expect(c, "INSERT INTO activity(id,company_id,kind) VALUES('act1','c1','TWEET')", True, "unknown activity kind rejected (SRT)")

# Every SRT column listed in build_schema.sh must carry a "-- SRT domain: X" comment in the base file, and no other column may.
import re

listed = dict(
    tuple(x.split(":")) for x in re.findall(r"(\w+\.\w+:[A-Z_]+)", (ROOT / "tools" / "build_schema.sh").read_text())
)
commented = {}
table = None
for line in (ROOT / "db" / "carmen" / "0001_init.base.sql").read_text().splitlines():
    t = re.match(r"\s*CREATE TABLE (\w+)", line)
    if t:
        table = t.group(1)
        continue
    col = re.match(r"\s+(\w+)\s+(TEXT|INTEGER|REAL|BLOB|NUMERIC)\b", line)
    com = re.search(r"-- SRT domain: ([A-Z_]+)", line)
    if col and com and table:
        commented[f"{table}.{col.group(1)}"] = com.group(1)
missing = sorted(k for k in listed if commented.get(k) != listed[k])
extra = sorted(k for k in commented if k not in listed)
failures += len(missing) + len(extra)
print(f"  [{'PASS' if not (missing or extra) else 'FAIL'}] SRT domain comments match build_schema.sh ({len(listed)} columns)")
for k in missing:
    print(f"    missing or wrong comment: {k} (expected SRT domain {listed[k]})")
for k in extra:
    print(f"    comment on a column not listed in build_schema.sh: {k}")

# The diagrams in doc/uml must be what gen_erd.py would write now.
sys.path.insert(0, str(ROOT / "tools"))
import gen_erd

expected = gen_erd.render_all()
actual = {p.name: p.read_text() for p in (ROOT / "doc" / "uml").glob("erd-*.puml")} if (ROOT / "doc" / "uml").is_dir() else {}
stale = sorted(n for n in expected if actual.get(n) != expected[n]) + sorted(n for n in actual if n not in expected)
failures += len(stale)
print(f"  [{'PASS' if not stale else 'FAIL'}] E/R diagrams in doc/uml are current ({len(expected)} files)")
for n in stale:
    print(f"    stale, missing, or unexpected: {n} (run ./tools/build_schema.sh)")

# Every enrichment hint on a rubric question must be a key in enrichment_key.
unknown = [r[0] for r in c.execute("SELECT enrichment_key FROM rubric_criterion WHERE enrichment_key IS NOT NULL AND enrichment_key NOT IN (SELECT key FROM enrichment_key)")]
failures += len(unknown)
print(f"  [{'PASS' if not unknown else 'FAIL'}] every rubric enrichment hint is a known key")
for k in unknown:
    print(f"    unknown hint: {k}")
expect(c, "INSERT INTO enrichment_key(key,label,value_type) VALUES('x_test','X','COLOUR')", True, "unknown enrichment value type rejected (SRT)")
expect(c, "INSERT INTO enrichment_fact(id,company_id,key,value) VALUES('ef3','c1','brand_new_key','anything')", False, "fact with a key not in enrichment_key accepted (keys stay open)")

print("ALL PASS" if failures == 0 else f"{failures} FAILURE(S)")
sys.exit(1 if failures else 0)
