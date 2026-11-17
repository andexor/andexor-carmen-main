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


c = sqlite3.connect(":memory:")
c.execute("PRAGMA foreign_keys=ON")
c.executescript((ROOT / "db" / "carmen" / "0001_init.sql").read_text())
tables = c.execute("select count(*) from sqlite_master where type='table'").fetchone()[0]
trig = c.execute("select count(*) from sqlite_master where type='trigger'").fetchone()[0]
print(f"carmen: loaded, {tables} tables, {trig} triggers")

# Every SRT domain used by a trigger must exist in srt.
used = {r[0].split(" not in ")[1].split("'")[0] for r in c.execute("select sql from sqlite_master where type='trigger'")}
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
expect(c, "INSERT INTO task(id,title) VALUES('t1','Call back')", False, "task with only a title accepted")
expect(c, "UPDATE task SET status='DONE' WHERE id='t1'", True, "DONE without completed_at rejected")
expect(c, "INSERT INTO document(id,company_id,agreement_id,file_name,content_type,size_bytes,sha256,r2_key) VALUES('doc1','c1','a1','msa.pdf','application/pdf',10,'ab','c1/doc1')", False, "document accepted")
expect(c, "INSERT INTO activity(id,company_id,kind) VALUES('act1','c1','TWEET')", True, "unknown activity kind rejected (SRT)")

print("ALL PASS" if failures == 0 else f"{failures} FAILURE(S)")
sys.exit(1 if failures else 0)
