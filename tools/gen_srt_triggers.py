"""Generate SRT enforcement triggers. Usage: python3 gen_srt_triggers.py table.column:DOMAIN ...
Prints SQL: for each table.column, a BEFORE INSERT and BEFORE UPDATE OF trigger that
raises if NEW.column is not NULL and not present in srt(domain, code)."""
import sys
# --replace-upd (migration 0002): drop and recreate only the UPDATE triggers so they check the column only when its value changes.
REPLACE = sys.argv[1:2] == ["--replace-upd"]
T = """CREATE TRIGGER srt_{t}_{c}_ins BEFORE INSERT ON {t}
WHEN NEW.{c} IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='{d}' AND code=NEW.{c} AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: {t}.{c} not in {d}'); END;
CREATE TRIGGER srt_{t}_{c}_upd BEFORE UPDATE OF {c} ON {t}
WHEN NEW.{c} IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='{d}' AND code=NEW.{c} AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: {t}.{c} not in {d}'); END;
"""
U = """DROP TRIGGER srt_{t}_{c}_upd;
CREATE TRIGGER srt_{t}_{c}_upd BEFORE UPDATE OF {c} ON {t}
WHEN NEW.{c} IS NOT NULL AND NEW.{c} IS NOT OLD.{c} AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='{d}' AND code=NEW.{c} AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: {t}.{c} not in {d}'); END;
"""
for spec in sys.argv[2 if REPLACE else 1:]:
    tc, d = spec.split(":"); t, c = tc.split(".")
    print((U if REPLACE else T).format(t=t, c=c, d=d))
