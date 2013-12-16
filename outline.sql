3 points Rails could do better with timestamps
- Default NOW() - database time, not app server time, (but safe from changes of app server times)
- NOT NULL- what good is auditing if its optional ?
- timestamptz - otherwise, just assume everyone inserts in UTC ?


References
- http://www.postgresql.org/docs/9.3/static/datatype-datetime.html
- http://wiki.postgresql.org/wiki/Todo#Dates_and_Times

Demo: Behavior of rails before/after constraints
- NULL
  - Impression.first.update_attributes :created_at, NULL
  - INSERT INTO impressions

- Default Now()
  - cant do in rails column DSL yet (expands now() ! )
  - needs execute SQL direct
  
- Timestamptz (Support- pg docs data width, and behavior)
  - Most people agree 'store UTC'
  - only timestamptz asserts what tz the timestamp is in (always UTC)
  - also converts to UTC on way in if needed

  CREATE TABLE travel_route_tz(
    "city" text,
    "timestamp" timestamptz
  );

  CREATE TABLE travel_route_notz(
    "city" text,
    "timestamp" timestamp
  );
  
  -- Got into London at 8:45AM
  INSERT INTO travel_route_tz (city, timestamp) VALUES ('London', '2013-01-01 08:45:00 UTC');
  SELECT * from travel_route;
  
  -- 2 hours 25 minutes to Lisbon (same time zone )
  INSERT INTO travel_route_tz (city, timestamp) VALUES ('Lisbon', '2013-01-01 11:10:00'); -- No tz specified !
  SELECT * from travel_route_tz;

  -- How did it interpret our timezone ?
  show timezone;

  -- 1 hours 8 minutes to Madrid (plus it's one time zone over)
  INSERT INTO travel_route_tz (city, timestamp) VALUES ('Madrid', '2013-01-01 13:18:00 CET');  
  SELECT * from travel_route_tz;

  -- Explanation: So all the times are stored in the UTC timezone, and misbehaving inserts are normalized
  --   (support pg docs data width)
  - discards incoming TZ info (PG TODO is out to keep it)

  
  -- Got into London at 8:45AM
  INSERT INTO travel_route_notz (city, timestamp) VALUES ('London', '2013-01-01 08:45:00 UTC');
  SELECT * from travel_route_notz;
  
  -- 2 hours 25 minutes to Lisbon (same time zone )
  INSERT INTO travel_route_notz (city, timestamp) VALUES ('Lisbon', '2013-01-01 11:10:00'); -- No tz specified !
  SELECT * from travel_route_notz;

  -- 1 hours 8 minutes to Madrid (plus it's one time zone over)
  INSERT INTO travel_route_notz (city, timestamp) VALUES ('Madrid', '2013-01-01 13:18:00 CET');  
  SELECT * from travel_route_notz;

  /*
  DROP TABLE travel_route_tz;
  DROP TABLE travel_route_notz;
  */

  /* PART DEUX */
    -- Are these null or not null ?
  SELECT table_name, column_name, is_nullable, column_default
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_name = 'travel_route_tz';
  
  ALTER TABLE travel_route_tz ALTER timestamp SET DEFAULT NOW();
  INSERT INTO travel_route_tz(city) VALUES('Helsinki');
  SELECT * FROM travel_route_tz;

  INSERT INTO travel_route_tz(city) VALUES('Prague');
  SELECT * from travel_route_tz;

  ALTER TABLE travel_route_tz ALTER timestamp SET DEFAULT 'NOW()';
  INSERT INTO travel_route_tz(city) VALUES('Nice');
  SELECT * FROM travel_route_tz;

  SELECT table_name, column_name, is_nullable, column_default
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_name = 'travel_route_tz';

  INSERT INTO travel_route_tz(city) VALUES('Vienna');
  INSERT INTO travel_route_tz(city) VALUES('Kiev');
  SELECT * from travel_route_tz;

  INSERT INTO travel_route_tz(city) VALUES('Prague');
  SELECT * from travel_route_tz;
  
  ALTER TABLE travel_route_tz ALTER timestamp SET DEFAULT 'NOW()';

  INSERT INTO travel_route_tz(city) VALUES('Tallinn');
  INSERT INTO travel_route_tz(city) VALUES('Moscow');
   
  
modified_at / modified_by - out of scope may require triggers / connections under separate identities, YMMV

Conclusion: Database constraints are about assuring the quality of incoming data.
App frameworks get part of it right, but usually not all.
Knowing how to tighten down your database schema is worth the care to get it right.


