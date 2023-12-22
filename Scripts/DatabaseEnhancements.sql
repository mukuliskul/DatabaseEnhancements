-- Error Codes used :
--- 1: success
-- -1: no data found
-- -2: many rows returned
-- -3: no row inserted/ updated/ deleted
-- -4: VALUE_ERROR
-- -5: others
-- -6: invalid cursor


SET SERVEROUTPUT ON;

/*
1:
This section outlines the creation of Stored Procedures (SPs) for the 'Players', 'Teams', and 'Rosters' tables to manage their respective CRUD (Create, Read, Update, Delete) operations. Each table will have specific SPs for inserting, updating, deleting, and selecting records:

1. spTableNameInsert: Inserts a new record. If the primary key (PK) uses an auto-numbering system, the SP returns the new PK value.
2. spTableNameUpdate: Updates an existing record given the PK value.
3. spTableNameDelete: Deletes a record based on its PK value.
4. spTableNameSelect: Retrieves all fields in a single row from a table given a PK value.

Naming convention for the SPs is spTableNameMethod (e.g., spPlayersInsert). These SPs exclude the use of DBMS_OUTPUT for output purposes. In case of debugging needs, any DBMS_OUTPUT should be commented out in the final version.

Each SP includes comprehensive exception handling tailored to the specific method and table. To facilitate error tracking, error codes are used, which should be consistent across all SPs. This consistency allows for a single error code table in the documentation.
*/
----------- CRUD for Players table -----------
/

CREATE OR REPLACE PROCEDURE spplayersinsert (
    pid players.playerid%type,
    regnum players.regnumber%type,
    lname players.lastname%type,
    fname players.firstname%type,
    isact players.isactive%type,
    codeerr OUT players.playerid%type
) AS
BEGIN
    IF isact = 0 OR isact = 1 OR isact IS NULL THEN
        INSERT INTO players VALUES (
            pid,
            regnum,
            lname,
            fname,
            isact
        );
    ELSE
        codeerr := -3;
    END IF;

    IF sql%rowcount = 1 THEN
        COMMIT;
        codeerr := 1;
    ELSE
        ROLLBACK;
        codeerr := -3; -- Not inserted
    END IF;
EXCEPTION
    WHEN value_error THEN
        codeerr := -4; -- Data type error
    WHEN dup_val_on_index THEN
        codeerr := -3; -- Primary key violation
    WHEN OTHERS THEN
        codeerr := -5; -- Other error
END spplayersinsert;
/

DECLARE
    v_errcode NUMBER;
BEGIN
 -- Non-existing Record
    spplayersinsert(101, '12345', 'Doe', 'John', 1, v_errcode);
    dbms_output.put_line('Existing Record Insert Error Code: '
                         || v_errcode);
 -- Existing Record
    spplayersinsert(374022, '23456', 'Brown', 'Alice', 1, v_errcode);
    dbms_output.put_line('Non-existing Record Insert Error Code: '
                         || v_errcode);
END;
/

CREATE OR REPLACE PROCEDURE spplayersupdate (
    pid players.playerid%type,
    regnum players.regnumber%type,
    lname players.lastname%type,
    fname players.firstname%type,
    isact players.isactive%type,
    codeerr OUT NUMBER
) AS
BEGIN
    IF isact = 0 OR isact = 1 OR isact IS NULL THEN
        UPDATE players
        SET
            regnumber = regnum,
            lastname = lname,
            firstname = fname,
            isactive = isact
        WHERE
            playerid = pid;
        IF sql%rowcount = 0 THEN
            codeerr := -1; -- No rows updated, could mean playerID does not exist
        ELSE
            COMMIT;
            codeerr := 1; -- Success
        END IF;
    ELSE
        codeerr := -3; -- Invalid isActive value
    END IF;
EXCEPTION
    WHEN value_error THEN
        codeerr := -4; -- Data type error
    WHEN OTHERS THEN
        codeerr := -5; -- Other error
END spplayersupdate;
/

DECLARE
    v_errcode NUMBER;
BEGIN
 -- Existing Record
    spplayersupdate(101, '54321', 'Doe', 'Jane', 0, v_errcode);
    dbms_output.put_line('Existing Record Update Error Code: '
                         || v_errcode);
 -- Non-existing Record
    spplayersupdate(300, '65432', 'Green', 'Bob', 1, v_errcode);
    dbms_output.put_line('Non-existing Record Update Error Code: '
                         || v_errcode);
END;
/

CREATE OR REPLACE PROCEDURE spplayersdelete (
    pid players.playerid%type,
    codeerr OUT NUMBER
) AS
BEGIN
    DELETE FROM players
    WHERE
        playerid = pid;
 -- Check if any row was affected
    IF sql%rowcount = 0 THEN
 -- No row was deleted, implying the player ID doesn't exist
        codeerr := -1; -- No Data Found
    ELSE
 -- Successful deletion
        COMMIT;
        codeerr := 1; -- Success
    END IF;
EXCEPTION
    WHEN value_error THEN
        codeerr := -4; -- Value Error
    WHEN OTHERS THEN
        codeerr := -5; -- Others (for unspecified exceptions)
END spplayersdelete;

/
DECLARE
    v_errcode NUMBER;
BEGIN
 -- Existing Record
    spplayersdelete(101, v_errcode);
    dbms_output.put_line('Existing Record Delete Error Code: '
                         || v_errcode);
 -- Non-existing Record
    spplayersdelete(300, v_errcode);
    dbms_output.put_line('Non-existing Record Delete Error Code: '
                         || v_errcode);
END;
/

CREATE OR REPLACE PROCEDURE spplayersselect(
    pid IN players.playerid%type,
    regnum OUT players.regnumber%type,
    lname OUT players.lastname%type,
    fname OUT players.firstname%type,
    isact OUT players.isactive%type,
    codeerr OUT NUMBER
) AS
BEGIN
    SELECT
        regnumber,
        lastname,
        firstname,
        isactive INTO regnum,
        lname,
        fname,
        isact
    FROM
        players
    WHERE
        playerid = pid;
 -- If the SELECT statement finds a row, SQL%ROWCOUNT will be 1
    IF sql%rowcount = 0 THEN
        codeerr := -1; -- No data found
    ELSE
        codeerr := 1; -- Success
    END IF;
EXCEPTION
    WHEN no_data_found THEN
        codeerr := -1; -- No data found
    WHEN too_many_rows THEN
        codeerr := -2; -- More than one row found
    WHEN value_error THEN
        codeerr := -4; -- Invalid number or data type
    WHEN OTHERS THEN
        codeerr := -5; -- Other error
END spplayersselect;
/

DECLARE
    pid       NUMBER;
    regnum    VARCHAR2(100);
    lname     VARCHAR2(100);
    fname     VARCHAR2(100);
    isact     NUMBER;
    v_errcode NUMBER;
BEGIN
 -- Existing Record
    pid := 374022;
    spplayersselect(pid, regnum, lname, fname, isact, v_errcode);
    IF v_errcode = 1 THEN
        dbms_output.put_line('Existing Record: '
                             || regnum
                             || ', '
                             || lname
                             || ', '
                             || fname
                             || ', '
                             || isact);
    ELSE
        dbms_output.put_line('Existing Record Error Code: '
                             || v_errcode);
    END IF;
 -- Non-existing Record
    pid := 300;
    spplayersselect(pid, regnum, lname, fname, isact, v_errcode);
    IF v_errcode = 1 THEN
        dbms_output.put_line('Non-existing Record: '
                             || regnum
                             || ', '
                             || lname
                             || ', '
                             || fname
                             || ', '
                             || isact);
    ELSE
        dbms_output.put_line('Non-existing Record Error Code: '
                             || v_errcode);
    END IF;
END;
/

----------- CRUD for Teams table -----------
CREATE OR REPLACE PROCEDURE spteamsinsert (
    tid teams.teamid%type,
    tname teams.teamname%type,
    isact teams.isactive%type,
    jcolor teams.jerseycolour%type,
    codeerr OUT NUMBER
) AS
BEGIN
    IF isact = 0 OR isact = 1 OR isact IS NULL THEN
        INSERT INTO teams VALUES (
            tid,
            tname,
            isact,
            jcolor
        );
        IF sql%rowcount = 1 THEN
            COMMIT;
            codeerr := 1;
        ELSE
            ROLLBACK;
            codeerr := -3;
        END IF;
    ELSE
        codeerr := -3;
    END IF;
EXCEPTION
    WHEN dup_val_on_index THEN
        codeerr := -3; -- Duplicate value
    WHEN value_error THEN
        codeerr := -4;
    WHEN OTHERS THEN
        codeerr := -5;
END spteamsinsert;
/

DECLARE
    v_errcode NUMBER;
BEGIN
 -- Attempt to insert a new team
    spteamsinsert(1001, 'Team A', 1, 'Blue', v_errcode);
    dbms_output.put_line('Insert Error Code: '
                         || v_errcode);
 -- Attempt to insert a duplicate team
    spteamsinsert(1001, 'Team B', 1, 'Red', v_errcode);
    dbms_output.put_line('Insert Error Code: '
                         || v_errcode);
END;
/

CREATE OR REPLACE PROCEDURE spteamsupdate (
    tid teams.teamid%type,
    tname teams.teamname%type,
    isact teams.isactive%type,
    jcolor teams.jerseycolour%type,
    codeerr OUT NUMBER
) AS
BEGIN
    IF isact = 0 OR isact = 1 OR isact IS NULL THEN
        UPDATE teams
        SET
            teamname = tname,
            isactive = isact,
            jerseycolour = jcolor
        WHERE
            teamid = tid;
        IF sql%rowcount = 0 THEN
            codeerr := -1; -- No rows updated, could mean teamID does not exist
        ELSE
            COMMIT;
            codeerr := 1; -- Success
        END IF;
    ELSE
        codeerr := -3; -- Invalid isActive value
    END IF;
EXCEPTION
    WHEN value_error THEN
        codeerr := -4; -- Data type error
    WHEN OTHERS THEN
        codeerr := -5; -- Other error
END spteamsupdate;
/

DECLARE
    v_errcode NUMBER;
BEGIN
 -- Update an existing team
    spteamsupdate(1001, 'Team ANew', 0, 'Green', v_errcode);
    dbms_output.put_line('Update Error Code: '
                         || v_errcode);
 -- Update a non-existing team
    spteamsupdate(9999, 'Non-existing Team', 1, 'Yellow', v_errcode);
    dbms_output.put_line('Update Error Code: '
                         || v_errcode);
END;
/

CREATE OR REPLACE PROCEDURE spteamsdelete (
    tid teams.teamid%type,
    codeerr OUT NUMBER
) AS
BEGIN
    DELETE FROM teams
    WHERE
        teamid = tid;
    IF sql%rowcount = 1 THEN
        COMMIT;
        codeerr := 1;
    ELSE
        ROLLBACK;
        codeerr := -3;
    END IF;
EXCEPTION
    WHEN value_error THEN
        codeerr := -4;
    WHEN OTHERS THEN
        codeerr := -5;
END spteamsdelete;
/

DECLARE
    v_errcode NUMBER;
BEGIN
 -- Delete an existing team
    spteamsdelete(1001, v_errcode);
    dbms_output.put_line('Delete Error Code: '
                         || v_errcode);
 -- Delete a non-existing team
    spteamsdelete(9999, v_errcode);
    dbms_output.put_line('Delete Error Code: '
                         || v_errcode);
END;
/

CREATE OR REPLACE PROCEDURE spteamsselect(
    tid IN teams.teamid%type,
    tname OUT teams.teamname%type,
    isact OUT teams.isactive%type,
    jcolor OUT teams.jerseycolour%type,
    codeerr OUT NUMBER
) AS
BEGIN
    SELECT
        teamname,
        isactive,
        jerseycolour INTO tname,
        isact,
        jcolor
    FROM
        teams
    WHERE
        teamid = tid;
    IF sql%rowcount = 1 THEN
        codeerr := 1;
    ELSE
        codeerr := -3;
    END IF;
EXCEPTION
    WHEN value_error THEN
        codeerr := -4;
    WHEN OTHERS THEN
        codeerr := -5;
END spteamsselect;
/

DECLARE
    tname     VARCHAR2(100);
    isact     NUMBER;
    jcolor    VARCHAR2(100);
    v_errcode NUMBER;
BEGIN
 -- Select an existing team
    spteamsselect(210, tname, isact, jcolor, v_errcode);
    IF v_errcode = 1 THEN
        dbms_output.put_line('Team Name: '
                             || tname
                             || ', IsActive: '
                             || isact
                             || ', Jersey Color: '
                             || jcolor);
    ELSE
        dbms_output.put_line('Select Error Code: '
                             || v_errcode);
    END IF;
 -- Select a non-existing team
    spteamsselect(9999, tname, isact, jcolor, v_errcode);
    dbms_output.put_line('Select Error Code: '
                         || v_errcode);
END;
/

----------- CRUD for Rosters table -----------
/

CREATE OR REPLACE PROCEDURE sprostersinsert (
    rid IN OUT rosters.rosterid%type,
    pid IN rosters.playerid%type,
    tid IN rosters.teamid%type,
    isact IN rosters.isactive%type,
    jnum IN rosters.jerseynumber%type,
    codeerr OUT NUMBER
) AS
    playerexist NUMBER;
    teamexist   NUMBER;
BEGIN
    codeerr := 1; -- Assume success initially
 -- Check if player and team exist
    SELECT
        COUNT(*) INTO playerexist
    FROM
        players
    WHERE
        playerid = pid;
    SELECT
        COUNT(*) INTO teamexist
    FROM
        teams
    WHERE
        teamid = tid;
    IF playerexist = 0 OR teamexist = 0 THEN
        codeerr := -1; -- No Data Found
        return;
    END IF;

    IF isact = 0 OR isact = 1 OR isact IS NULL THEN
        INSERT INTO rosters (
            rosterid,
            playerid,
            teamid,
            isactive,
            jerseynumber
        ) VALUES (
            rid,
            pid,
            tid,
            isact,
            jnum
        );
        IF sql%rowcount = 0 THEN
            codeerr := -3; -- No Row Inserted
            return;
        END IF;

        COMMIT;
    ELSE
        codeerr := -6; -- Invalid isActive value
        return;
    END IF;
EXCEPTION
    WHEN dup_val_on_index THEN
        ROLLBACK;
        codeerr := -3; -- Duplicate value
    WHEN value_error THEN
        ROLLBACK;
        codeerr := -4; -- Value Error
    WHEN OTHERS THEN
        ROLLBACK;
        codeerr := -5; -- Other errors
END sprostersinsert;
/

DECLARE
    rid       rosters.rosterid%type := 1100;
    vid       rosters.rosterid%type := 100;
    v_errcode rosters.rosterid%type;
BEGIN
 -- Prepare a new roster ID (assuming 1100 doesn't exist)
    sprostersinsert(rid, 963874, 221, 1, 99, v_errcode);
    dbms_output.put_line('Insert Error Code (New Record): '
                         || v_errcode);
 -- Prepare an existing roster ID (assuming 100 already exists)
    sprostersinsert(vid, 1000894, 212, 1, 88, v_errcode);
    dbms_output.put_line('Insert Error Code (Existing Record): '
                         || v_errcode);
END;
/

CREATE OR REPLACE PROCEDURE sprostersupdate (
    rid rosters.rosterid%type,
    pid rosters.playerid%type,
    tid rosters.teamid%type,
    isact rosters.isactive%type,
    jnum rosters.jerseynumber%type,
    codeerr OUT NUMBER
) AS
BEGIN
    IF isact = 0 OR isact = 1 OR isact IS NULL THEN
        UPDATE rosters
        SET
            playerid = pid,
            teamid = tid,
            isactive = isact,
            jerseynumber = jnum
        WHERE
            rosterid = rid;
        IF sql%rowcount = 0 THEN
            codeerr := -3; -- No rows updated
        ELSE
            codeerr := 1; -- Success
        END IF;
    ELSE
        codeerr := -6; -- Invalid isActive value
    END IF;
EXCEPTION
    WHEN dup_val_on_index THEN
        ROLLBACK;
        codeerr := -3; -- Duplicate value (considering as "No rows updated")
    WHEN value_error THEN
        ROLLBACK;
        codeerr := -4; -- Invalid data type
    WHEN OTHERS THEN
        ROLLBACK;
        codeerr := -5; -- Other errors
END sprostersupdate;
/

/

DECLARE
    v_errcode NUMBER;
BEGIN
 -- Update an existing roster (assuming 1100 exists)
    sprostersupdate(1100, 11, 21, 0, 98, v_errcode);
    dbms_output.put_line('Update Error Code (Existing Record): '
                         || v_errcode);
 -- Update a non-existing roster
    sprostersupdate(9999, 12, 22, 1, 77, v_errcode);
    dbms_output.put_line('Update Error Code (Non-existing Record): '
                         || v_errcode);
END;
/

CREATE OR REPLACE PROCEDURE sprostersdelete (
    rid rosters.rosterid%type,
    codeerr OUT NUMBER
) AS
BEGIN
    DELETE FROM rosters
    WHERE
        rosterid = rid;
    IF sql%rowcount = 0 THEN
        ROLLBACK;
        codeerr := -1; -- No rows deleted
    ELSE
        COMMIT;
        codeerr := 1; -- Success
    END IF;
EXCEPTION
    WHEN value_error THEN
        ROLLBACK;
        codeerr := -4; -- Invalid data type
    WHEN OTHERS THEN
        ROLLBACK;
        codeerr := -5; -- Other errors
END sprostersdelete;
/

DECLARE
    v_errcode NUMBER;
BEGIN
 -- Delete an existing roster (assuming 1100 exists)
    sprostersdelete(1100, v_errcode);
    dbms_output.put_line('Delete Error Code (Existing Record): '
                         || v_errcode);
 -- Delete a non-existing roster
    sprostersdelete(9999, v_errcode);
    dbms_output.put_line('Delete Error Code (Non-existing Record): '
                         || v_errcode);
END;
/

CREATE OR REPLACE PROCEDURE sprostersselect(
    rid IN rosters.rosterid%type,
    pid OUT rosters.playerid%type,
    tid OUT rosters.teamid%type,
    isact OUT rosters.isactive%type,
    jnum OUT rosters.jerseynumber%type,
    codeerr OUT NUMBER
) AS
BEGIN
    SELECT
        playerid,
        teamid,
        isactive,
        jerseynumber INTO pid,
        tid,
        isact,
        jnum
    FROM
        rosters
    WHERE
        rosterid = rid;
 -- If the SELECT statement finds a row, SQL%ROWCOUNT will be 1
    IF sql%rowcount = 0 THEN
        codeerr := -1; -- No data found
    ELSE
        codeerr := 1; -- Success
    END IF;
EXCEPTION
    WHEN no_data_found THEN
        codeerr := -1; -- No data found
    WHEN too_many_rows THEN
        codeerr := -2; -- More than one row found
    WHEN value_error THEN
        codeerr := -4; -- Invalid number or data type
    WHEN OTHERS THEN
        codeerr := -5; -- Other error
END sprostersselect;
/

DECLARE
    pid       NUMBER;
    tid       NUMBER;
    isact     NUMBER;
    jnum      NUMBER;
    v_errcode NUMBER;
BEGIN
 -- Select an existing roster (assuming 100 exists)
    sprostersselect(100, pid, tid, isact, jnum, v_errcode);
    IF v_errcode = 1 THEN
        dbms_output.put_line('Existing Roster: Player ID: '
                             || pid
                             || ', Team ID: '
                             || tid
                             || ', IsActive: '
                             || isact
                             || ', Jersey Number: '
                             || jnum);
    ELSE
        dbms_output.put_line('Select Error Code (Existing Record): '
                             || v_errcode);
    END IF;
 -- Select a non-existing roster
    sprostersselect(9999, pid, tid, isact, jnum, v_errcode);
    IF v_errcode = -1 THEN
        dbms_output.put_line('Select Error Code (Non-existing Record): '
                             || v_errcode);
    END IF;
END;
/

/*
2:
This section details the creation of Stored Procedures designed to display the complete contents of the 'Players', 'Teams', and 'Rosters' tables. Each table has a dedicated procedure named spTableNameSelectAll, which executes a standard SELECT * FROM <tablename> query and outputs the results using DBMS_OUTPUT.

The procedures iterate over each row in their respective tables and print each record's details. The output format is a comma-separated list of the table's fields. Additionally, each procedure implements error handling and returns an error code indicating the operation's success or failure.
*/

/

----------- PLAYERS TABLE -----------
CREATE OR REPLACE PROCEDURE spplayersselectall (
    codeerr OUT players.playerid%type
)AS
    CURSOR c IS
    SELECT
        playerid
    FROM
        players;
    regnum players.regnumber%type;
    lname  players.lastname%type;
    fname  players.firstname%type;
    isact  players.isactive%type;
BEGIN
    FOR i IN c LOOP
        spplayersselect(i.playerid, regnum, lname, fname, isact, codeerr);
        dbms_output.put_line(i.playerid
                             || ', '
                             || regnum
                             || ', '
                             || lname
                             || ', '
                             || fname
                             || ', '
                             || isact);
    END LOOP;

    codeerr := 1;
EXCEPTION
    WHEN OTHERS THEN
        codeerr := -5;
END spplayersselectall;
/

// Version 2

CREATE OR REPLACE PROCEDURE spplayersselectall (
    codeerr OUT players.playerid%type
) AS
    CURSOR c IS
    SELECT
        playerid,
        regnumber,
        lastname,
        firstname,
        isactive
    FROM
        players;
BEGIN
    FOR i IN c LOOP
        dbms_output.put_line(i.playerid
                             || ', '
                             || i.regnumber
                             || ', '
                             || i.lastname
                             || ', '
                             || i.firstname
                             || ', '
                             || i.isactive);
    END LOOP;

    codeerr := 1;
EXCEPTION
    WHEN OTHERS THEN
        codeerr := -5;
END spplayersselectall;
/

DECLARE
    codeerr players.playerid%type;
BEGIN
    spplayersselectall(codeerr);
END;
/

----------- TEAMS TABLE -----------
CREATE OR REPLACE PROCEDURE spteamsselectall (
    codeerr OUT teams.teamid%type
)AS
    CURSOR c IS
    SELECT
        teamid
    FROM
        teams;
    tname  teams.teamname%type;
    isact  teams.isactive%type;
    jcolor teams.jerseycolour%type;
BEGIN
    FOR i IN c LOOP
        spteamsselect(i.teamid, tname, isact, jcolor, codeerr);
        dbms_output.put_line(i.teamid
                             || ', '
                             || tname
                             || ', '
                             || isact
                             || ', '
                             || jcolor );
    END LOOP;

    codeerr := 1;
EXCEPTION
    WHEN OTHERS THEN
        codeerr := -5;
END spteamsselectall;
/

// Version 2

CREATE OR REPLACE PROCEDURE spteamsselectall (
    codeerr OUT teams.teamid%type
) AS
    CURSOR c IS
    SELECT
        teamid,
        teamname,
        isactive,
        jerseycolour
    FROM
        teams;
BEGIN
    FOR i IN c LOOP
        dbms_output.put_line(i.teamid
                             || ', '
                             || i.teamname
                             || ', '
                             || i.isactive
                             || ', '
                             || i.jerseycolour);
    END LOOP;

    codeerr := 1;
EXCEPTION
    WHEN OTHERS THEN
        codeerr := -5;
END spteamsselectall;
/

DECLARE
    codeerr teams.teamid%type;
BEGIN
    spteamsselectall(codeerr);
END;
/

----------- ROSTERS TABLE -----------
CREATE OR REPLACE PROCEDURE sprostersselectall(
    codeerr OUT rosters.rosterid%type
) AS
    CURSOR c IS
    SELECT
        rosterid
    FROM
        rosters;
    pid   rosters.playerid%type;
    tid   rosters.teamid%type;
    jnum  rosters.jerseynumber%type;
    isact rosters.isactive%type;
BEGIN
    FOR i IN c LOOP
        sprostersselect(i.rosterid, pid, tid, isact, jnum, codeerr);
        dbms_output.put_line(i.rosterid
                             || ', '
                             || pid
                             || ', '
                             || tid
                             || ', '
                             || isact
                             || ', '
                             || jnum);
    END LOOP;

    codeerr := 1;
EXCEPTION
    WHEN OTHERS THEN
        codeerr := -5;
END sprostersselectall;
/

// Version 2

CREATE OR REPLACE PROCEDURE sprostersselectall (
    codeerr OUT rosters.rosterid%type
) AS
    CURSOR c IS
    SELECT
        rosterid,
        playerid,
        teamid,
        isactive,
        jerseynumber
    FROM
        rosters;
BEGIN
    FOR i IN c LOOP
        dbms_output.put_line(i.rosterid
                             || ', '
                             || i.playerid
                             || ', '
                             || i.teamid
                             || ', '
                             || i.isactive
                             || ', '
                             || i.jerseynumber);
    END LOOP;

    codeerr := 1;
EXCEPTION
    WHEN OTHERS THEN
        codeerr := -5;
END sprostersselectall;
/

DECLARE
    codeerr rosters.rosterid%type;
BEGIN
    sprostersselectall(codeerr);
END;
/

/*
3:
These stored procedures are designed to fetch and display the entire tables of 'players', 'teams', and 'rosters'. Each procedure - spPlayersSelectTable, spTeamsSelectTable, and spRostersSelectTable - is tailored to its respective table and outputs the complete set of records using a SYS_REFCURSOR. The output is formatted and displayed to the script window through DBMS_OUTPUT, providing a user-friendly view of the data.

Key Aspects:
- spPlayersSelectTable: Fetches all records from the 'players' table, displaying player ID, registration number, names, and active status.
- spTeamsSelectTable: Retrieves all records from the 'teams' table, showing team ID, team name, active status, and jersey color.
- spRostersSelectTable: Gathers all records from the 'rosters' table, including roster ID, player ID, team ID, active status, and jersey number.

Each procedure operates by:
- Opening a SYS_REFCURSOR for a SELECT statement to fetch the required data.
- Iterating over the fetched rows and using DBMS_OUTPUT to print out each record's details in a formatted manner.
- Including error handling to manage exceptions and set an error code for any issues encountered during execution.

These procedures are particularly useful for administrators and analysts who need to quickly access and review comprehensive data from these tables in a readable format.
*/
----------- PLAYERS TABLE -----------
/

CREATE OR REPLACE PROCEDURE spplayersselecttable(
    c OUT SYS_REFCURSOR,
    codeerr OUT players.playerid%type
) AS
BEGIN
    OPEN c FOR
        SELECT
            *
        FROM
            players;
    codeerr := 1; -- Success
EXCEPTION
    WHEN invalid_cursor THEN
        codeerr := -6; -- Invalid cursor
    WHEN value_error THEN
        codeerr := -4; -- Value error
    WHEN OTHERS THEN
        codeerr := -5; -- Other unspecified exceptions
END spplayersselecttable;
/

DECLARE
    c       SYS_REFCURSOR;
    player  players%rowtype;
    codeerr players.playerid%type;
BEGIN
    spplayersselecttable(c, codeerr);
    dbms_output.put_line('Player ID | Registration Number | Last Name | First Name | Is Active');
    dbms_output.put_line('----------+--------------------+-----------+------------+----------');
    LOOP
        FETCH c INTO player;
        EXIT WHEN c%notfound;
        dbms_output.put_line( lpad(player.playerid, 9)
                              || ' | '
                              || lpad(player.regnumber, 18)
                                 || ' | '
                                 || lpad(player.lastname, 9)
                                    || ' | '
                                    || lpad(player.firstname, 10)
                                       || ' | '
                                       || lpad(player.isactive, 9) );
    END LOOP;

    CLOSE c;
    IF codeerr != 1 THEN
        dbms_output.put_line('Error occurred with code: '
                             || codeerr);
    END IF;
END;
/

----------- TEAMS TABLE -----------
/

CREATE OR REPLACE PROCEDURE spteamsselecttable(
    c OUT SYS_REFCURSOR,
    codeerr OUT teams.teamid%type
) AS
BEGIN
    OPEN c FOR
        SELECT
            *
        FROM
            teams;
    codeerr := 1; -- Success
EXCEPTION
    WHEN invalid_cursor THEN
        codeerr := -6; -- Invalid cursor
    WHEN value_error THEN
        codeerr := -4; -- Value error
    WHEN OTHERS THEN
        codeerr := -5; -- Other unspecified exceptions
END spteamsselecttable;
/

DECLARE
    c       SYS_REFCURSOR;
    team    teams%rowtype;
    codeerr teams.teamid%type;
BEGIN
    spteamsselecttable(c, codeerr);
    dbms_output.put_line('Team ID | Team Name        | Is Active | Jersey Colour');
    dbms_output.put_line('--------+------------------+-----------+--------------');
    LOOP
        FETCH c INTO team;
        EXIT WHEN c%notfound;
        dbms_output.put_line( lpad(team.teamid, 7)
                              || ' | '
                              || rpad(team.teamname, 16)
                                 || ' | '
                                 || lpad(team.isactive, 9)
                                    || ' | '
                                    || rpad(team.jerseycolour, 13) );
    END LOOP;

    CLOSE c;
    IF codeerr != 1 THEN
        dbms_output.put_line('Error occurred with code: '
                             || codeerr);
    END IF;
END;
/

----------- RosterTable -----------
CREATE OR REPLACE PROCEDURE sprostersselecttable(
    c OUT SYS_REFCURSOR,
    codeerr OUT rosters.rosterid%type
) AS
BEGIN
    OPEN c FOR
        SELECT
            *
        FROM
            rosters;
    codeerr := 1; -- Success
EXCEPTION
    WHEN invalid_cursor THEN
        codeerr := -6; -- Invalid cursor
    WHEN value_error THEN
        codeerr := -4; -- Value error
    WHEN OTHERS THEN
        codeerr := -5; -- Other unspecified exceptions
END sprostersselecttable;
/

DECLARE
    c       SYS_REFCURSOR;
    roster  rosters%rowtype;
    codeerr rosters.rosterid%type;
BEGIN
    sprostersselecttable(c, codeerr);
    dbms_output.put_line('Roster ID | Player ID | Team ID | Is Active | Jersey Number');
    dbms_output.put_line('----------+-----------+---------+-----------+---------------');
    LOOP
        FETCH c INTO roster;
        EXIT WHEN c%notfound;
        dbms_output.put_line( lpad(roster.rosterid, 9)
                              || ' | '
                              || lpad(roster.playerid, 9)
                                 || ' | '
                                 || lpad(roster.teamid, 7)
                                    || ' | '
                                    || lpad(roster.isactive, 9)
                                       || ' | '
                                       || rpad(roster.jerseynumber, 15) );
    END LOOP;

    CLOSE c;
    IF codeerr != 1 THEN
        dbms_output.put_line('Error occurred with code: '
                             || codeerr);
    END IF;
END;
/

/*
4:
The vwPlayerRosters view is created to offer a unified view of the data related to players and their respective teams. This view is particularly useful for obtaining a complete picture of players' associations with teams, including their personal details and team-related information.

Structure of vwPlayerRosters:
- Roster ID, Player ID, and Team ID: Serve as the key identifiers linking players to teams.
- Team Name: Provides the name of the team to which the player belongs.
- Player Name (Last Name and First Name): Offers the full name of the player.
- Registration Number: Indicates the player's registration number.
- Jersey Colour and Number: Details the jersey attributes of the player.
- Active Status: Indicates whether the player, team, and roster are currently active.

This view simplifies queries that require comprehensive data about players on teams, making it an invaluable resource for team managers, coaches, and sports analysts.
*/
/

----------- vwPlayerRosters -----------
/

CREATE OR REPLACE VIEW vwplayerrosters AS
    SELECT
        rosterid,
        r.playerid,
        r.teamid,
        teamname,
        lastname,
        firstname,
        regnumber,
        jerseycolour,
        jerseynumber,
        p.isactive   AS playeractive,
        t.isactive   AS teamactive,
        t.isactive   AS rosteractive
    FROM
        rosters r
        JOIN players p
        ON r.playerid = p.playerid JOIN teams t
        ON r.teamid = t.teamid;

/

SELECT
    playerid,
    firstname,
    lastname,
    regnumber,
    teamname
FROM
    vwplayerrosters
WHERE
    teamname LIKE '%Aurora%';

/

/*
5 :
The spTeamRosterByID stored procedure is designed to display the roster of a specific team, identified by the input parameter 'teamID'. This procedure utilizes the vwPlayerRosters view to retrieve detailed player information for the specified team. Two versions of this procedure are presented, each employing a different method to fetch and display the roster data.

Version 1 - Using SYS_REFCURSOR:
- This version accepts 'teamID' as an input parameter and uses a SYS_REFCURSOR to fetch the team roster.
- The cursor dynamically retrieves data from vwPlayerRosters where the team ID matches the input.
- It outputs player details such as name, team name, and jersey information using DBMS_OUTPUT.
- The procedure includes error handling for various scenarios, assigning specific error codes for different exceptions.

Version 2 - Using Explicit Cursor:
- Similar in functionality to Version 1, this version explicitly declares a cursor for more controlled data retrieval.
- It iterates through the fetched records, displaying detailed information about each player on the team.
- A row counter is implemented to track the number of records fetched, enabling the procedure to identify if no data is found for the given team ID.
- Comprehensive error handling is included, covering scenarios like no data found, too many rows, and other exceptions.

Both versions aim to provide an efficient way to access detailed player information for a given team, catering to different needs and preferences in data handling and retrieval.
*/
----------- spTeamRosterByID -----------
/

CREATE OR REPLACE PROCEDURE spteamrosterbyid (
    tid IN teams.teamid%type,
    mycursor OUT SYS_REFCURSOR,
    codeerr OUT NUMBER
) AS
BEGIN
    OPEN mycursor FOR
        SELECT
            *
        FROM
            vwplayerrosters
        WHERE
            teamid = tid;
    IF mycursor%isopen THEN
        codeerr := 1; -- Success
    ELSE
        codeerr := -6; -- Cursor not opened
    END IF;
EXCEPTION
    WHEN value_error THEN
        codeerr := -4; -- Invalid value
    WHEN OTHERS THEN
        codeerr := -5; -- Other errors
END spteamrosterbyid;
/

DECLARE
    mycursor     SYS_REFCURSOR;
    rosterrecord vwplayerrosters%rowtype;
    v_errcode    NUMBER;
BEGIN
    spteamrosterbyid(215, mycursor, v_errcode);
    IF v_errcode = 1 THEN
        LOOP
            FETCH mycursor INTO rosterrecord;
            EXIT WHEN mycursor%notfound;
            dbms_output.put_line('Player Name: '
                                 || rosterrecord.firstname
                                 || ' '
                                 || rosterrecord.lastname
                                 || ', Team Name: '
                                 || rosterrecord.teamname
                                 || ', Jersey Colour: '
                                 || rosterrecord.jerseycolour
                                 || ', Jersey Number: '
                                 || rosterrecord.jerseynumber);
        END LOOP;

        CLOSE mycursor;
    ELSE
        dbms_output.put_line('Error Code: '
                             || v_errcode);
    END IF;
END;
/

--------------------- Version2  ---------------------
CREATE OR REPLACE PROCEDURE spteamrosterbyid (
    tid IN teams.teamid%type,
    codeerr OUT NUMBER
) AS
    CURSOR teamrostercursor IS
    SELECT
        firstname,
        lastname,
        playeractive,
        teamname,
        jerseycolour,
        jerseynumber
    FROM
        vwplayerrosters
    WHERE
        teamid = tid;
    rosterrecord teamrostercursor%rowtype;
    rowcount     NUMBER := 0; -- Counter to track the number of rows fetched
BEGIN
    OPEN teamrostercursor;
    LOOP
        FETCH teamrostercursor INTO rosterrecord;
        EXIT WHEN teamrostercursor%notfound;
 -- Increase row count for each fetched record
        rowcount := rowcount + 1;
        dbms_output.put_line('Player Name: '
                             || rosterrecord.firstname
                             || ' '
                             || rosterrecord.lastname
                             || ', Team Name: '
                             || rosterrecord.teamname
                             || ', Jersey Colour: '
                             || rosterrecord.jerseycolour
                             || ', Jersey Number: '
                             || rosterrecord.jerseynumber);
    END LOOP;

    CLOSE teamrostercursor;
 -- Check if any rows were fetched
    IF rowcount = 0 THEN
        codeerr := -3; -- No data found for the given team ID
    ELSE
        codeerr := 1; -- Success
    END IF;
EXCEPTION
    WHEN no_data_found THEN
        codeerr := -1; -- No data found
    WHEN too_many_rows THEN
        codeerr := -2; -- More than one row found
    WHEN OTHERS THEN
        codeerr := -5; -- Other errors
END spteamrosterbyid;
/

DECLARE
    v_errcode NUMBER;
BEGIN
    spteamrosterbyid(215, v_errcode); -- Replace 215 to ...
    IF v_errcode != 1 THEN
        dbms_output.put_line('Error Code: '
                             || v_errcode);
    END IF;
END;
/

/*
6 :
The spTeamRosterByName stored procedure is tailored to facilitate searching for and displaying team rosters based on a part of a team's name. This procedure is especially useful when the exact name of the team is not known, as it allows for partial name searches.

Key Features of spTeamRosterByName:
- Search Flexibility: Users can input any part of a team's name as the search string, enhancing the procedure's utility in various scenarios.
- Comprehensive Roster Details: For teams that match the search criteria, the procedure outputs a detailed roster. This includes player names, team names, and jersey details, providing a complete picture of the team composition.
- Case-Insensitive Search: The procedure performs a case-insensitive search, ensuring that it captures all relevant matches regardless of how the search string is entered.
- Error Handling: Robust error handling is incorporated to manage potential issues like invalid cursors or value errors, with specific error codes returned for different error types.

This stored procedure is an invaluable tool for team administrators, coaches, and sports analysts who need to access team rosters efficiently, even with limited information about a team's name.
*/
/

----------- spTeamRosterByName -----------

-- Create the spTeamRosterByName procedure
CREATE OR REPLACE PROCEDURE spteamrosterbyname (
    searchstr IN VARCHAR2,
    mycursor OUT SYS_REFCURSOR,
    codeerr OUT NUMBER
) AS
BEGIN
    OPEN mycursor FOR
        SELECT
            *
        FROM
            vwplayerrosters
        WHERE
            upper(teamname) LIKE '%'
                                 || trim(upper(searchstr))
                                 || '%';
    codeerr := 1;
EXCEPTION
    WHEN invalid_cursor THEN
        codeerr := -6;
    WHEN value_error THEN
        codeerr := -4;
    WHEN OTHERS THEN
        codeerr := -5;
END spteamrosterbyname;
/

-- Execute the spTeamRosterByName procedure
DECLARE
    mycursor  SYS_REFCURSOR;
    rosterrow vwplayerrosters%rowtype;
    searchstr VARCHAR2(100);
    codeerr   NUMBER;
BEGIN
    searchstr := '&searchStr'; -- Prompt for the search string input
    spteamrosterbyname(searchstr, mycursor, codeerr);
 -- Print header
    dbms_output.put_line('---------------------------------------------');
    dbms_output.put_line('Player Name           Team Name        Jersey');
    dbms_output.put_line('---------------------------------------------');
    LOOP
        FETCH mycursor INTO rosterrow;
        EXIT WHEN mycursor%notfound;
 -- Format the output
        dbms_output.put_line( rpad(rosterrow.firstname
                                   || ' '
                                   || rosterrow.lastname, 23)
                              || rpad(rosterrow.teamname, 15)
                                 || rosterrow.jerseycolour
                                 || ' '
                                 || rosterrow.jerseynumber );
    END LOOP;
 -- Print footer
    dbms_output.put_line('---------------------------------------------');
    CLOSE mycursor;
EXCEPTION
    WHEN OTHERS THEN
        codeerr := -5;
END;
/

/*
7 :
The vwTeamsNumPlayers view is crafted to provide a quick and efficient overview of the number of players registered on each team within a league or organization. By aggregating data from the 'rosters' table, this view simplifies the process of determining team sizes, which is essential for managing team rosters and analyzing team compositions.

Key Aspects of vwTeamsNumPlayers:
- Team ID: Each record in the view corresponds to a unique team, identified by its team ID.
- Number of Players: The view calculates the total number of players registered to each team, offering an immediate insight into team sizes.
- Order: The results are ordered by the team ID, making it easy to locate specific teams and compare their sizes.

This view is particularly useful for coaches, league administrators, and analysts who need to frequently assess team compositions and monitor player distributions across different teams.
*/
----------- vwTeamsNumPlayers -----------
CREATE OR REPLACE VIEW vwteamsnumplayers AS
    SELECT
        teamid,
        COUNT(playerid) AS numofplayers
    FROM
        rosters r
    GROUP BY
        teamid
    ORDER BY
        teamid;

----------- Query the vwTeamsNumPlayers -----------
/

SELECT
    *
FROM
    vwteamsnumplayers;

/

/*
8 :
The fncNumPlayersByTeamID function is a user-defined function that efficiently retrieves the current number of registered players for a specified team, identified by its team ID (primary key). This function utilizes the vwTeamsNumPlayers view, which contains the pre-aggregated number of players per team.

Key aspects of fncNumPlayersByTeamID:
- Input Parameter: It accepts the team ID (tid) as an input parameter.
- Return Value: The function returns the count of registered players for the specified team.
- Error Handling: The function includes comprehensive error handling, which covers scenarios like value errors, no data found, too many rows returned, and other unexpected exceptions. In case of errors, specific error codes are returned.

This function is particularly useful for quickly determining the team size, aiding in team management and statistical analysis.
*/

/

----------- fncNumPlayersByTeamID -----------
CREATE OR REPLACE FUNCTION fncnumplayersbyteamid (
    tid teams.teamid%type
) RETURN NUMBER IS
    numplayers NUMBER;
BEGIN
    SELECT
        numofplayers INTO numplayers
    FROM
        vwteamsnumplayers
    WHERE
        teamid = tid;
    RETURN numplayers;
EXCEPTION
    WHEN value_error THEN
        RETURN -4;
    WHEN no_data_found THEN
        RETURN -1;
    WHEN too_many_rows THEN
        RETURN -2;
    WHEN OTHERS THEN
        RETURN -5;
END fncnumplayersbyteamid;
/

----------- Execute fncNumPlayersByTeamID -----------
DECLARE
    teamid     teams.teamid%type := 215; -- Replace with the desired team ID
    numplayers NUMBER;
    codeerr    NUMBER;
BEGIN
    numplayers := fncnumplayersbyteamid(teamid);
 -- Check for specific error conditions
    IF numplayers < 0 THEN
        dbms_output.put_line('Error code: '
                             || numplayers);
    ELSE
        dbms_output.put_line('Number of players for Team '
                             || teamid
                             || ': '
                             || numplayers);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error occurred with code: '
                             || codeerr);
END;
/

/*
9 :
The vwSchedule view is created to offer a comprehensive overview of all games, enhancing the basic game information with human-readable names for teams and locations. This view facilitates easier understanding and analysis by including both the key identifiers and the descriptive names for teams and locations.

The structure of vwSchedule includes:
- Game ID, number, date and time.
- Home and visiting team IDs and their respective names.
- Game scores for both teams.
- Location ID and name.
- Game status (played or not) and any additional notes.
*/

----------- vwSchedule -----------
CREATE OR REPLACE VIEW vwschedule AS
    SELECT
        g.gameid,
        g.gamenum,
        g.gamedatetime,
        g.hometeam      AS hometeamid,
        (
            SELECT
                teamname
            FROM
                teams
            WHERE
                teamid = g.hometeam
        ) AS hometeamname,
        g.homescore,
        g.visitteam AS visitteamid,
        (
            SELECT
                teamname
            FROM
                teams
            WHERE
                teamid = g.visitteam
        ) AS visitteamname,
        g.visitscore,
        g.locationid,
        sl.locationname,
        g.isplayed,
        g.notes
    FROM
        games       g
        JOIN teams t
        ON t.teamid = g.hometeam
        OR t.teamid = g.visitteam JOIN sllocations sl
        ON sl.locationid = g.locationid;

/

SELECT
    gameid,
    gamenum,
    gamedatetime,
    hometeamid,
    locationname
FROM
    vwschedule;

/

/*
10 :
The spSchedUpcomingGames stored procedure is a tool designed to display the schedule of upcoming games within a specified number of days, as determined by the input parameter 'n'. This allows users to dynamically query for games happening in the near future, with the flexibility to specify the timeframe of interest.

Key Features:
- Dynamic Timeframe: Users can specify how many days into the future they wish to view the game schedule, making the procedure versatile for different planning needs.
- Comprehensive Game Details: For each upcoming game within the specified timeframe, the procedure outputs detailed information including game ID, number, date and time, teams involved, scores, location, whether the game has been played, and any additional notes.
- Error Handling: The procedure includes error handling mechanisms to manage any potential issues during execution, such as value errors or unexpected exceptions. It provides an error code output parameter 'codeerr' to indicate the success or type of error encountered.

This stored procedure is particularly valuable for sports administrators, teams, and fans who need to stay informed about upcoming games.
*/

/

----------- spSchedUpcomingGames -----------
CREATE OR REPLACE PROCEDURE spschedupcominggames (
    n NUMBER,
    codeerr OUT NUMBER
) AS
    CURSOR mycursor IS
    SELECT
        *
    FROM
        vwschedule
    WHERE
        gamedatetime BETWEEN sysdate AND (sysdate + n);
    schedule vwschedule%rowtype;
BEGIN
    OPEN mycursor;
    LOOP
        FETCH mycursor INTO schedule;
        EXIT WHEN mycursor%notfound;
        dbms_output.put_line('Game ID: '
                             || schedule.gameid);
        dbms_output.put_line('Game Number: '
                             || schedule.gamenum);
        dbms_output.put_line('Game Date and Time: '
                             || to_char(schedule.gamedatetime, 'MM/DD/YYYY HH24:MI:SS'));
        dbms_output.put_line('Home Team: '
                             || schedule.hometeamname);
        dbms_output.put_line('Home Team Score: '
                             || schedule.homescore);
        dbms_output.put_line('Visiting Team: '
                             || schedule.visitteamname);
        dbms_output.put_line('Visiting Team Score: '
                             || schedule.visitscore);
        dbms_output.put_line('Location: '
                             || schedule.locationname);
        dbms_output.put_line('Is Played: '
                             || schedule.isplayed);
        dbms_output.put_line('Notes: '
                             || schedule.notes);
        dbms_output.put_line('-------------------');
    END LOOP;

    CLOSE mycursor;
    codeerr := 1;
EXCEPTION
    WHEN value_error THEN
        codeerr := -4;
    WHEN OTHERS THEN
        codeerr := -5;
END spschedupcominggames;
/

----------- Execute spSchedUpcomingGames -----------
DECLARE
    codeerr NUMBER;
BEGIN
    spschedupcominggames(20, codeerr);
    IF codeerr = 1 THEN
        dbms_output.put_line('Procedure executed successfully.');
    ELSE
        dbms_output.put_line('Error occurred with code: '
                             || codeerr);
    END IF;
END;
/

/*
11 :
The spSchedPastGames stored procedure is crafted to efficiently retrieve and display a list of games played within the past 'n' days, where 'n' is a dynamic input parameter. This procedure ensures that the output is relevant for any given day of the year, providing a flexible and responsive way to view recent game results.

Key features of this procedure include:
- Dynamic Date Range: It calculates the date range dynamically based on the current system date and the input parameter 'n', ensuring the data is always up to date.
- Comprehensive Output: Utilizing DBMS_OUTPUT, the procedure prints detailed information about each game, including game ID, number, date and time, team names and scores, location, play status, and any additional notes.
- Error Handling: The procedure includes error handling, which sets an output parameter 'codeerr' to specific values depending on the type of error encountered.

This procedure is particularly useful for generating quick reports on recent games, making it a valuable tool for league managers, analysts, or fans looking for up-to-date game information.
*/

----------- spSchedPastGames -----------

CREATE OR REPLACE PROCEDURE spschedpastgames (
    n NUMBER,
    codeerr OUT NUMBER
) AS
    CURSOR mycursor IS
    SELECT
        *
    FROM
        vwschedule
    WHERE
        gamedatetime BETWEEN (sysdate - n) AND sysdate;
    schedule vwschedule%rowtype;
BEGIN
    OPEN mycursor;
    LOOP
        FETCH mycursor INTO schedule;
        EXIT WHEN mycursor%notfound;
 -- Display game details using DBMS_OUTPUT
        dbms_output.put_line('Game ID: '
                             || schedule.gameid);
        dbms_output.put_line('Game Number: '
                             || schedule.gamenum);
        dbms_output.put_line('Game Date and Time: '
                             || to_char(schedule.gamedatetime, 'MM/DD/YYYY HH24:MI:SS'));
        dbms_output.put_line('Home Team: '
                             || schedule.hometeamname);
        dbms_output.put_line('Home Team Score: '
                             || schedule.homescore);
        dbms_output.put_line('Visiting Team: '
                             || schedule.visitteamname);
        dbms_output.put_line('Visiting Team Score: '
                             || schedule.visitscore);
        dbms_output.put_line('Location: '
                             || schedule.locationname);
        dbms_output.put_line('Is Played: '
                             || schedule.isplayed);
        dbms_output.put_line('Notes: '
                             || schedule.notes);
        dbms_output.put_line('-------------------');
    END LOOP;

    CLOSE mycursor;
    codeerr := 1;
EXCEPTION
    WHEN value_error THEN
        codeerr := -4;
    WHEN OTHERS THEN
        codeerr := -5;
END spschedpastgames;
/

----------- Execute spSchedPastGames -----------
DECLARE
    codeerr NUMBER;
BEGIN
    spschedpastgames(7, codeerr); -- Display games played in the past 7 days
    IF codeerr = 1 THEN
        dbms_output.put_line('Procedure executed successfully.');
    ELSE
        dbms_output.put_line('Error occurred with code: '
                             || codeerr);
    END IF;
END;
/

/*
12 :
This script describes the creation of a Stored Procedure named spRunStandings, which is tasked with populating a temporary static table named tempStandings. The purpose of this procedure is to calculate and display the current standings based on existing game data.

The tempStandings table is structured to hold the team ID, team name, and aggregated statistics like games played, wins, losses, ties, points, goals for, goals against, and goal differential. The calculation involves aggregating data from both perspectives - as the home team and as the visiting team.

The process involves:
- Counting the number of games played by each team.
- Summing up the total wins, losses, and ties.
- Calculating the total points, which are determined as '3 points for a win and 1 point for a tie'.
- Computing goals for and against, and the goal differential (goals for minus goals against).

This comprehensive calculation provides a detailed view of each team's performance in the league.
*/
----------- Table tempStandings -----------
/

CREATE TABLE tempstandings AS (
    SELECT
        theteamid,
        (
            SELECT
                teamname
            FROM
                teams
            WHERE
                teamid = t.theteamid
        ) AS teamname,
        SUM(gamesplayed) AS gp,
        SUM(wins) AS w,
        SUM(losses) AS l,
        SUM(ties) AS t,
        SUM(wins) * 3 + SUM(ties) AS pts,
        SUM(goalsfor) AS gf,
        SUM(goalsagainst) AS ga,
        SUM(goalsfor) - SUM(goalsagainst) AS gd
    FROM
        (
            SELECT
                hometeam        AS theteamid,
                COUNT(gameid)   AS gamesplayed,
                SUM(homescore)  AS goalsfor,
                SUM(visitscore) AS goalsagainst,
                SUM(
                    CASE
                        WHEN homescore > visitscore THEN
                            1
                        ELSE
                            0
                    END)        AS wins,
                SUM(
                    CASE
                        WHEN homescore < visitscore THEN
                            1
                        ELSE
                            0
                    END)        AS losses,
                SUM(
                    CASE
                        WHEN homescore = visitscore THEN
                            1
                        ELSE
                            0
                    END)        AS ties
            FROM
                games
            WHERE
                isplayed = 1
            GROUP BY
                hometeam
            UNION
            ALL
 -- perspective of the visiting team
            SELECT
                visitteam       AS theteamid,
                COUNT(gameid)   AS gamesplayed,
                SUM(visitscore) AS goalsfor,
                SUM(homescore)  AS goalsagainst,
                SUM(
                    CASE
                        WHEN homescore < visitscore THEN
                            1
                        ELSE
                            0
                    END)        AS wins,
                SUM(
                    CASE
                        WHEN homescore > visitscore THEN
                            1
                        ELSE
                            0
                    END)        AS losses,
                SUM(
                    CASE
                        WHEN homescore = visitscore THEN
                            1
                        ELSE
                            0
                    END)        AS ties
            FROM
                games
            WHERE
                isplayed = 1
            GROUP BY
                visitteam
        )     t
    GROUP BY
        theteamid
);

/

/*
13 :
This section introduces the creation of a database trigger, trgupdatestandings, which is set to activate after an INSERT or UPDATE operation on the homescore, isplayed, or visitscore columns of the games table. The purpose of this trigger is to maintain real-time accuracy in the tempStandings table, ensuring it always reflects the latest standings in the system.

Upon triggering, the trgupdatestandings performs two key operations on the tempStandings table:
1. It first clears existing data with a DELETE operation.
2. Then, it populates tempStandings with the latest standings information. This computation involves aggregating data such as games played, wins, losses, ties, points, goals for and against, and goal difference for each team, considering both their performances as home and visiting teams.

This trigger ensures that any change in game results immediately updates the standings, allowing users or software systems to retrieve up-to-date standings information with a simple SELECT query on the tempStandings table.
*/
----------- trgUpdateStandings -----------
/

-- Create or replace the stored procedure
CREATE OR REPLACE TRIGGER trgupdatestandings AFTER
    INSERT OR UPDATE OF homescore, isplayed, visitscore ON games
BEGIN
    DELETE FROM tempstandings;
    INSERT INTO tempstandings (
        SELECT
            theteamid,
            (
                SELECT
                    teamname
                FROM
                    teams
                WHERE
                    teamid = t.theteamid
            ) AS teamname,
            SUM(gamesplayed) AS gp,
            SUM(wins) AS w,
            SUM(losses) AS l,
            SUM(ties) AS t,
            SUM(wins) * 3 + SUM(ties) AS pts,
            SUM(goalsfor) AS gf,
            SUM(goalsagainst) AS ga,
            SUM(goalsfor) - SUM(goalsagainst) AS gd
        FROM
            (
 -- from the home team perspective
                SELECT
                    hometeam        AS theteamid,
                    COUNT(gameid)   AS gamesplayed,
                    SUM(homescore)  AS goalsfor,
                    SUM(visitscore) AS goalsagainst,
                    SUM(
                        CASE
                            WHEN homescore > visitscore THEN
                                1
                            ELSE
                                0
                        END)        AS wins,
                    SUM(
                        CASE
                            WHEN homescore < visitscore THEN
                                1
                            ELSE
                                0
                        END)        AS losses,
                    SUM(
                        CASE
                            WHEN homescore = visitscore THEN
                                1
                            ELSE
                                0
                        END)        AS ties
                FROM
                    games
                WHERE
                    isplayed = 1
                GROUP BY
                    hometeam
                UNION
                ALL
 -- from the perspective of the visiting team
                SELECT
                    visitteam       AS theteamid,
                    COUNT(gameid)   AS gamesplayed,
                    SUM(visitscore) AS goalsfor,
                    SUM(homescore)  AS goalsagainst,
                    SUM(
                        CASE
                            WHEN homescore < visitscore THEN
                                1
                            ELSE
                                0
                        END)        AS wins,
                    SUM(
                        CASE
                            WHEN homescore > visitscore THEN
                                1
                            ELSE
                                0
                        END)        AS losses,
                    SUM(
                        CASE
                            WHEN homescore = visitscore THEN
                                1
                            ELSE
                                0
                        END)        AS ties
                FROM
                    games
                WHERE
                    isplayed = 1
                GROUP BY
                    visitteam
            )     t
        GROUP BY
            theteamid
    );
END;
/

SELECT
    *
FROM
    tempstandings;

/

/*
14 :
Objective:
The goal of this PL/SQL script is to determine the winner of the golden boot (an award given to the player with the most goals throughout the tournament). 
To make it more challenging we decided to present the number of goals scored by each team, along with the statistics of the top scorers from those respective teams in a stored procedure, it gives up-to-date stats whenever the procedure is run since it is directly retreiving information from table goalscorers. 
The output should be presented in descending order of team goals, and the winner of golden boot is mentioned at the end of the output

Procedure:
- spgetgoldenbootstats: This stored procedure calculates and displays the total goals scored by each team and identifies the player with the highest number of goals for each team. It then determines the overall winner of the Golden Boot (player with the highest total goals across all teams) and prints the winner's details, including player name, player ID, team name, and team ID. We used nested loops to iterate through teams and players, keep track of the player with the highest goals. The final result is printed using dbms_output.put_line.


Output Format:
-------------------------------------
Team ID: ......
Team Name: ......
Total Goals: ......
Player ID: ......
Full Name: ......
Num Goals: ......
-------------------------------------

The golden boot winner is outputted in the following format :
-------------------------------------
Winner of Golden Boot: ......... (id: .......) from ........ (id: ......)
-------------------------------------
*/
/

CREATE OR REPLACE PROCEDURE spgetgoldenbootstats IS
    highestgoals           NUMBER := 0;
    goldenbootplayerid     goalscorers.playerid%type;
    goldenbootplayerteamid goalscorers.teamid%type;
    goldenbootplayerteam   teams.teamname%type;
    goldenbootplayer       VARCHAR2(100);
BEGIN
    dbms_output.put_line('*****  START  *****');
    FOR teamrec IN (
        SELECT
            t.teamid,
            t.teamname,
            SUM(gs.numgoals) AS "TotalGoals"
        FROM
            teams       t
            JOIN goalscorers gs
            ON t.teamid = gs.teamid
        GROUP BY
            t.teamid,
            t.teamname
        ORDER BY
            "TotalGoals" DESC
    ) LOOP
        dbms_output.put_line('Team ID: '
                             || teamrec.teamid);
        dbms_output.put_line('Team Name: '
                             || teamrec.teamname);
        dbms_output.put_line('Total Goals: '
                             || teamrec."TotalGoals");
        FOR playerrec IN (
            SELECT
                playerid,
                "FullName",
                MAX("PlayerGoals") AS "PlayerGoals"
            FROM
                (
                    SELECT
                        gs.playerid,
                        p.firstname
                        || ' '
                        || p.lastname    AS "FullName",
                        SUM(gs.numgoals) AS "PlayerGoals"
                    FROM
                        goalscorers gs
                        JOIN players p
                        ON gs.playerid = p.playerid
                    WHERE
                        gs.teamid = teamrec.teamid
                    GROUP BY
                        gs.teamid,
                        gs.playerid,
                        p.firstname,
                        p.lastname
                )
            GROUP BY
                playerid,
                "FullName"
            ORDER BY
                "PlayerGoals" DESC
        ) LOOP
            dbms_output.put_line('Player ID: '
                                 || playerrec.playerid);
            dbms_output.put_line('Full Name: '
                                 || playerrec."FullName");
            dbms_output.put_line('Num Goals: '
                                 || playerrec."PlayerGoals");
 -- Check if the current player has the highest goals
            IF playerrec."PlayerGoals" > highestgoals THEN
                highestgoals := playerrec."PlayerGoals";
                goldenbootplayerid := playerrec.playerid;
                goldenbootplayerteam := teamrec.teamname;
                goldenbootplayerteamid := teamrec.teamid;
                goldenbootplayer := playerrec."FullName";
            END IF;

            dbms_output.put_line('-------------------------------------');
            exit; -- Exit after printing the top player for each team else proceeds to print the remaining players
        END LOOP;
    END LOOP;
 -- Print "Winner of Golden Boot" if the highest goals player is found
    IF goldenbootplayer IS NOT NULL THEN
        dbms_output.put_line('Winner of Golden Boot: '
                             || goldenbootplayer
                             || ' (id: '
                             || goldenbootplayerid
                             || ') '
                             || 'from '
                             || goldenbootplayerteam
                             || ' (id: '
                             || goldenbootplayerteamid
                             || ') ' );
        goldenbootplayer := NULL; -- Reset for the next team
        dbms_output.put_line('-------------------------------------');
    END IF;

    dbms_output.put_line('*****  END  *****');
END spgetgoldenbootstats;
/

BEGIN
    spgetgoldenbootstats;
END;
/