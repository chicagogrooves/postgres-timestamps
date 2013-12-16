How to do better with PG timestamps and Rails

 - timestamptz, not "timestamp without time zone"
 - NOT NULL
 - Default to NOW()


References
- http://www.postgresql.org/docs/9.3/static/datatype-datetime.html
- http://wiki.postgresql.org/wiki/Todo#Dates_and_Times

Terminal settings 108x40 (larger font)

Migration: 
class CreateTravelStop < ActiveRecord::Migration
  def change
    # An arrival in a city at a certain time along a stop
    create_table :travel_stops_rails do |t|
      t.column :city, :text
      t.timestamps
    end
  end
end

--DELETE FROM travel_stops_rails WHERE 1=1;
t = TravelStop.create city: "Chicago"
SELECT * FROM travel_stops_rails;
INSERT INTO travel_stops_rails(city) VALUES ('Boston');
SELECT * FROM travel_stops_rails;
t.update_attributes :created_at, NULL
SELECT * FROM travel_stops_rails;

Demo: Behavior of rails before/after constraints
- NULL
  - INSERT INTO impressions

- Default Now()
  - cant do in rails column DSL yet (expands now() ! )
  - needs execute SQL direct
  
- Timestamptz (Support- pg docs data width, and behavior)
  - Most people agree 'store UTC'
  - only timestamptz asserts what tz the timestamp is in (always UTC)
  - also converts to UTC on way in if needed

  CREATE TABLE travel_stops_tz(
    "city" text,
    "created_at" timestamptz
  );

  SELECT * from travel_stops_

  -- Got into London at 8:45AM
  INSERT INTO travel_stops_tz (city, created_at) VALUES ('London', '2013-01-01 08:45:00 UTC');
  SELECT * from travel_stops_tz;
  
  -- 2 hours 25 minutes to Lisbon (same time zone )
  INSERT INTO travel_stops_tz (city, created_at) VALUES ('Lisbon', '2013-01-01 11:10:00'); -- No tz specified !
  SELECT * from travel_stops_tz;

  -- How did it interpret our timezone ?
  show timezone;

  -- 1 hours 8 minutes to Madrid (plus it's one time zone over)
  INSERT INTO travel_stops_tz (city, created_at) VALUES ('Madrid', '2013-01-01 13:18:00 CET');  
  SELECT * from travel_stops_tz;

  -- Explanation: So all the times are stored in the UTC timezone, and misbehaving inserts are normalized
  --   (support pg docs data width)
  - discards incoming TZ info (PG TODO is out to keep it)

  CREATE TABLE travel_stops_notz(
    "city" text,
    "created_at" timestamp
  );
  
  -- Got into London at 8:45AM
  INSERT INTO travel_stops_rails (city, created_at) VALUES ('London', '2013-01-01 08:45:00 UTC');
  SELECT * from travel_stops_rails;
  
  -- 2 hours 25 minutes to Lisbon (same time zone )
  INSERT INTO travel_stops_rails (city, created_at) VALUES ('Lisbon', '2013-01-01 11:10:00'); -- No tz specified !
  SELECT * from travel_stops_rails;

  -- 1 hours 8 minutes to Madrid (plus it's one time zone over)
  INSERT INTO travel_stops_rails (city, created_at) VALUES ('Madrid', '2013-01-01 13:18:00 CET');  
  SELECT * from travel_stops_rails;

  /*
  DROP TABLE travel_stops_tz;
  DROP TABLE travel_stops_notz;
  */

  /* PART DEUX */
    -- Are these null or not null ?
  SELECT table_name, column_name, is_nullable, column_default
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_name = 'travel_stop_tz';
  
  ALTER TABLE travel_stop_tz ALTER timestamp SET DEFAULT NOW();
  INSERT INTO travel_stop_tz(city) VALUES('Helsinki');
  SELECT * FROM travel_stop_tz;

  INSERT INTO travel_stop_tz(city) VALUES('Prague');
  SELECT * from travel_stop_tz;

  ALTER TABLE travel_stop_tz ALTER timestamp SET DEFAULT 'NOW()';
  INSERT INTO travel_stop_tz(city) VALUES('Nice');
  SELECT * FROM travel_stop_tz;

  SELECT table_name, column_name, is_nullable, column_default
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_name = 'travel_stop_tz';

  INSERT INTO travel_stop_tz(city) VALUES('Vienna');
  INSERT INTO travel_stop_tz(city) VALUES('Kiev');
  SELECT * from travel_stop_tz;

  INSERT INTO travel_stop_tz(city) VALUES('Prague');
  SELECT * from travel_stop_tz;
  
  ALTER TABLE travel_stop_tz ALTER timestamp SET DEFAULT 'NOW()';

  INSERT INTO travel_stop_tz(city) VALUES('Tallinn');
  INSERT INTO travel_stop_tz(city) VALUES('Moscow');
   
  
modified_at / modified_by - out of scope may require triggers / connections under separate identities, YMMV

Conclusion: Database constraints are about assuring the quality of incoming data.
App frameworks get part of it right, but usually not all.
Knowing how to tighten down your database schema is worth the care to get it right.


