/*============================================================================
  File:     sp_SQLskills_SQL2008_finddupes.sql

  Summary:  Run against a single database this procedure will list ALL
            duplicate indexes and the needed TSQL to drop them!
					
  Date:     July 2011
			August 2014 - Merged in code from 20110715_sp_sqlskills_sql2008_finddupes_helpindex.sql and 20110715_sp_sqlskills_exposecolsinindexlevels_include_unordered.sql

  SQL Server 2008 Version
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp, SYSolutions, Inc.

  For more scripts and sample code, check out 
    http://www.SQLskills.com

  This script is intended only as a supplement to demos and lectures
  given by SQLskills instructors.  
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

USE master
go

if OBJECTPROPERTY(OBJECT_ID('sp_SQLskills_SQL2008_FindDupes'), 'IsProcedure') = 1
	drop procedure sp_SQLskills_SQL2008_FindDupes
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_SQLskills_SQL2008_FindDupes]
(
    @ObjName nvarchar(776) = NULL		-- the table to check for duplicates
                                        -- when NULL it will check ALL tables
)
AS

	-- Version History:	
	-- July 2011      klt - 1 to find duplicate indexes.
	-- August 2014    mem - Merged in code from 20110715_sp_sqlskills_sql2008_finddupes_helpindex.sql and 20110715_sp_sqlskills_exposecolsinindexlevels_include_unordered.sql

	-- Contact info
	-- See my blog for updates and/or additional information
	-- http://www.SQLskills.com/blogs/Kimberly (Kimberly L. Tripp)
	
	SET NOCOUNT ON
	
	DECLARE @ObjID int,			-- the object id of the table
			@DBName	sysname,
			@SchemaName sysname,
			@TableName sysname,
			@ExecStr nvarchar(4000),
			@multiTable tinyint = 0
	
	-- Check to see that the object names are local to the current database.
	SELECT @DBName = PARSENAME(@ObjName,3)
	
	IF @DBName IS NULL
	    SELECT @DBName = db_name()
	ELSE 
	IF @DBName <> db_name()
	    BEGIN
		    RAISERROR(15250,-1,-1)
		    -- select * from sys.messages where message_id = 15250
		    RETURN (1)
	    END
	
	IF @DBName = N'tempdb'
	    BEGIN
		    RAISERROR('WARNING: This procedure cannot be run against tempdb. Skipping tempdb.', 10, 0)
		    RETURN (1)
	    END
	
	-- Check to see the the table exists and initialize @ObjID.
	SELECT @SchemaName = PARSENAME(@ObjName, 2)
	
	IF @SchemaName IS NULL
	    SELECT @SchemaName = SCHEMA_NAME()
	
	
	-- Check to see the the table exists and initialize @ObjID.
	IF @ObjName IS NOT NULL
	BEGIN
	    SELECT @ObjID = object_id(@ObjName)
		Set @multiTable= 1

	    IF @ObjID is NULL
	    BEGIN
	        RAISERROR(15009,-1,-1,@ObjName,@DBName)
	        -- select * from sys.messages where message_id = 15009
	        RETURN (1)
	    END
	END
	
	
	CREATE TABLE #DropIndexes
	(
	    DatabaseName    sysname,
	    SchemaName      sysname,
	    TableName       sysname,
	    IndexName       sysname,
	    DropStatement   nvarchar(2000)
	)
	
	CREATE TABLE #FindDupes
	(
	    index_id int,
		is_disabled bit,
		index_name sysname,
		index_description varchar(210),
		index_keys nvarchar(2126),
	    included_columns nvarchar(max),
		filter_definition nvarchar(max),
		columns_in_tree nvarchar(2126),
		columns_in_leaf nvarchar(max)
	)

	-- create additional temp tables
	CREATE TABLE #spindtab
	(
		index_name			sysname	collate database_default NOT NULL,
		index_id			int,
		ignore_dup_key		bit,
		is_unique			bit,
		is_hypothetical		bit,
		is_primary_key		bit,
		is_unique_key		bit,
		is_disabled         bit,
		auto_created		bit,
		no_recompute		bit,
		groupname			sysname collate database_default NULL,
		index_keys			nvarchar(2126)	collate database_default NOT NULL, -- see @keys above for length descr
		filter_definition	nvarchar(max),
		inc_Count			smallint,
		inc_columns			nvarchar(max),
		cols_in_tree		nvarchar(2126),
		cols_in_leaf		nvarchar(max)
	)

	CREATE TABLE #IncludedColumns
	(	RowNumber	smallint,
		[Name]	nvarchar(128)
	)

	
	-- OPEN CURSOR OVER TABLE(S)
	IF @ObjName IS NOT NULL
	    DECLARE TableCursor CURSOR LOCAL STATIC FOR
	        SELECT @SchemaName, PARSENAME(@ObjName, 1)
	ELSE
	    DECLARE TableCursor CURSOR LOCAL STATIC FOR 		    
	        SELECT schema_name(uid), name 
	        FROM sysobjects 
	        WHERE type = 'U' --AND name
	        ORDER BY schema_name(uid), name
		    
	OPEN TableCursor 
	
	FETCH TableCursor
	    INTO @SchemaName, @TableName
	
	-- For each table, list the add the duplicate indexes and save 
	-- the info in a temporary table that we'll print out at the end.
	
	WHILE @@fetch_status >= 0
	BEGIN
	    TRUNCATE TABLE #FindDupes
	    
	    Set @objName = QUOTENAME(@SchemaName) + N'.'  + QUOTENAME(@TableName)
	
	
		-- <sp_SQLSkills_SQL2008_finddupes_helpindex>
	
			--November 2010: Added a column to show if an index is disabled.
			--     May 2010: Added tree/leaf columns to the output - this requires the 
			--               stored procedure: sp_SQLskills_ExposeColsInIndexLevels
			--               (Better known as sp_helpindex8)
			--   March 2010: Added index_id to the output (ordered by index_id as well)
			--  August 2008: Fixed a bug (missing begin/end block) AND I found
			--               a few other issues that people hadn't noticed (yikes!)!
			--   April 2008: Updated to add included columns to the output. 
			
			
			-- See my blog for updates and/or additional information
			-- http://www.SQLskills.com/blogs/Kimberly (Kimberly L. Tripp)
	
		declare @indid smallint,	-- the index id of an index
				@groupid int,  		-- the filegroup id of an index
				@indname sysname,
				@groupname sysname,
				@status int,
				@keys nvarchar(2126),	--Length (16*max_identifierLength)+(15*2)+(16*3)
				@inc_columns	nvarchar(max),
				@inc_Count		smallint,
				@loop_inc_Count		smallint,
				@ignore_dup_key	bit,
				@is_unique		bit,
				@is_hypothetical	bit,
				@is_primary_key	bit,
				@is_unique_key 	bit,
				@is_disabled    bit,
				@auto_created	bit,
				@no_recompute	bit,
				@filter_definition	nvarchar(max),
				@ColsInTree nvarchar(2126),
				@ColsInLeaf nvarchar(max)
	
		-- Check to see that the object names are local to the current database.
		select @dbname = parsename(@objname,3)
		if @dbname is null
			select @dbname = db_name()
		else if @dbname <> db_name()
			begin
				raiserror(15250,-1,-1)
				Goto FetchNextTable
			end
	
		-- Check to see the the table exists and initialize @objid.
		select @objid = object_id(@objname)
		if @objid is NULL
		begin
			raiserror(15009,-1,-1,@objname,@dbname)
			Goto FetchNextTable
		end
	
		-- OPEN CURSOR OVER INDEXES (skip stats: bug shiloh_51196)
		declare ms_crs_ind cursor local static for
			select i.index_id, i.data_space_id, QUOTENAME(i.name, N']') AS name,
				i.ignore_dup_key, i.is_unique, i.is_hypothetical, i.is_primary_key, i.is_unique_constraint,
				s.auto_created, s.no_recompute, i.filter_definition, i.is_disabled
			from sys.indexes as i 
				join sys.stats as s
					on i.object_id = s.object_id 
						and i.index_id = s.stats_id
			where i.object_id = @objid
		open ms_crs_ind
		fetch ms_crs_ind into @indid, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,
				@is_primary_key, @is_unique_key, @auto_created, @no_recompute, @filter_definition, @is_disabled
	
		-- IF NO INDEX, QUIT
		if @@fetch_status < 0
		begin
			deallocate ms_crs_ind
			--raiserror(15472,-1,-1,@objname) -- Object does not have any indexes.
			Goto FetchNextTable
		end
	
		-- truncate our working tables
		truncate table #spindtab
		truncate table #IncludedColumns

		-- Now check out each index, figure out its type and keys and
		--	save the info in a temporary table that we'll print out at the end.
		while @@fetch_status >= 0
		begin
			-- First we'll figure out what the keys are.
			declare @i int, @thiskey nvarchar(131) -- 128+3
	
			select @keys = QUOTENAME(index_col(@objname, @indid, 1), N']'), @i = 2
			if (indexkey_property(@objid, @indid, 1, 'isdescending') = 1)
				select @keys = @keys  + '(-)'
	
			select @thiskey = QUOTENAME(index_col(@objname, @indid, @i), N']')
			if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))
				select @thiskey = @thiskey + '(-)'
	
			while (@thiskey is not null )
			begin
				select @keys = @keys + ', ' + @thiskey, @i = @i + 1
				select @thiskey = QUOTENAME(index_col(@objname, @indid, @i), N']')
				if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))
					select @thiskey = @thiskey + '(-)'
			end
	
			-- Second, we'll figure out what the included columns are.
			select @inc_columns = NULL
			
			SELECT @inc_Count = count(*)
			FROM sys.tables AS tbl
			INNER JOIN sys.indexes AS si 
				ON (si.index_id > 0 
					and si.is_hypothetical = 0) 
					AND (si.object_id=tbl.object_id)
			INNER JOIN sys.index_columns AS ic 
				ON (ic.column_id > 0 
					and (ic.key_ordinal > 0 or ic.partition_ordinal = 0 or ic.is_included_column != 0)) 
					AND (ic.index_id=CAST(si.index_id AS int) AND ic.object_id=si.object_id)
			INNER JOIN sys.columns AS clmns 
				ON clmns.object_id = ic.object_id 
				and clmns.column_id = ic.column_id
			WHERE ic.is_included_column = 1 and
				(si.index_id = @indid) and 
				(tbl.object_id= @objid)
	
			IF @inc_Count > 0
			BEGIN
				DELETE FROM #IncludedColumns
				INSERT #IncludedColumns
					SELECT ROW_NUMBER() OVER (ORDER BY clmns.column_id) 
					, clmns.name 
					FROM
					sys.tables AS tbl
					INNER JOIN sys.indexes AS si 
						ON (si.index_id > 0 
							and si.is_hypothetical = 0) 
							AND (si.object_id=tbl.object_id)
					INNER JOIN sys.index_columns AS ic 
						ON (ic.column_id > 0 
							and (ic.key_ordinal > 0 or ic.partition_ordinal = 0 or ic.is_included_column != 0)) 
							AND (ic.index_id=CAST(si.index_id AS int) AND ic.object_id=si.object_id)
					INNER JOIN sys.columns AS clmns 
						ON clmns.object_id = ic.object_id 
						and clmns.column_id = ic.column_id
					WHERE ic.is_included_column = 1 and
						(si.index_id = @indid) and 
						(tbl.object_id= @objid)
				
				SELECT @inc_columns = QUOTENAME([Name], N']') FROM #IncludedColumns WHERE RowNumber = 1
	
				SET @loop_inc_Count = 1
	
				WHILE @loop_inc_Count < @inc_Count
				BEGIN
					SELECT @inc_columns = @inc_columns + ', ' + QUOTENAME([Name], N']') 
						FROM #IncludedColumns WHERE RowNumber = @loop_inc_Count + 1
					SET @loop_inc_Count = @loop_inc_Count + 1
				END
			END
		
			select @groupname = null
			select @groupname = name from sys.data_spaces where data_space_id = @groupid
	
			-- Get the column list for the tree and leaf level, for all nonclustered indexes IF the table has a clustered index
			IF @indid = 1 AND (SELECT is_unique FROM sys.indexes WHERE index_id = 1 AND object_id = @objid) = 0
				SELECT @ColsInTree = @keys + N', UNIQUIFIER', @ColsInLeaf = N'All columns "included" - the leaf level IS the data row, plus the UNIQUIFIER'
				
			IF @indid = 1 AND (SELECT is_unique FROM sys.indexes WHERE index_id = 1 AND object_id = @objid) = 1
				SELECT @ColsInTree = @keys, @ColsInLeaf = N'All columns "included" - the leaf level IS the data row.'
			
			IF @indid > 1 AND (SELECT COUNT(*) FROM sys.indexes WHERE index_id = 1 AND object_id = @objid) = 1
	
			--<ExposeCols>
			
				declare @nonclus_uniq int
						, @column_id int
						, @column_name nvarchar(260)
						, @col_descending bit
						, @colstr	nvarchar (max);
			
				-- Get clustered index keys (id and name)
				select sic.column_id, QUOTENAME(sc.name, N']') AS column_name, is_descending_key
				into #clus_keys 
				from sys.index_columns AS sic
					JOIN sys.columns AS sc
						ON sic.column_id = sc.column_id AND sc.object_id = sic.object_id
				where sic.[object_id] = @objid
				and [index_id] = 1;
				
				-- Get nonclustered index keys
				select sic.column_id, sic.is_included_column, QUOTENAME(sc.name, N']') AS column_name, is_descending_key
				into #nonclus_keys 
				from sys.index_columns AS sic
					JOIN sys.columns AS sc
						ON sic.column_id = sc.column_id 
							AND sc.object_id = sic.object_id
				where sic.[object_id] = @objid
					and sic.[index_id] = @indid;
					
				-- Is the nonclustered unique?
				select @nonclus_uniq = is_unique 
				from sys.indexes
				where [object_id] = @objid
					and [index_id] = @indid;
			
				if (@nonclus_uniq = 0)
				begin
					-- Case 1: nonunique nonclustered index
			
					-- cursor for nonclus columns not included and
					-- nonclus columns included but also clus keys
					declare mycursor cursor for
						select column_id, column_name, is_descending_key  
						from #nonclus_keys
						where is_included_column = 0
					open mycursor;
					fetch next from mycursor into @column_id, @column_name, @col_descending;
					WHILE @@FETCH_STATUS = 0
					begin
						select @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)' ELSE N'' END + N', ';
						fetch next from mycursor into @column_id, @column_name, @col_descending;
					end
					close mycursor;
					deallocate mycursor;
					
					-- cursor over clus_keys if clustered
					declare mycursor cursor for
						select column_id, column_name, is_descending_key from #clus_keys
						where column_id not in (select column_id from #nonclus_keys
							where is_included_column = 0)
					open mycursor;
					fetch next from mycursor into @column_id, @column_name, @col_descending;
					WHILE @@FETCH_STATUS = 0
					begin
						select @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)' ELSE N'' END + N', ';
						fetch next from mycursor into @column_id, @column_name, @col_descending;
					end
					close mycursor;
					deallocate mycursor;	
					
					select @ColsInTree = substring(@colstr, 1, LEN(@colstr) -1);
						
					-- find columns not in the nc and not in cl - that are still left to be included.
					declare mycursor cursor for
						select column_id, column_name, is_descending_key from #nonclus_keys
						where column_id not in (select column_id from #clus_keys UNION select column_id from #nonclus_keys where is_included_column = 0)
						order by column_name
					open mycursor;
					fetch next from mycursor into @column_id, @column_name, @col_descending;
					WHILE @@FETCH_STATUS = 0
					begin
						select @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)' ELSE N'' END + N', ';
						fetch next from mycursor into @column_id, @column_name, @col_descending;
					end
					close mycursor;
					deallocate mycursor;	
					
					select @ColsInLeaf = substring(@colstr, 1, LEN(@colstr) -1);
					
				end
			
				-- Case 2: unique nonclustered
				else
				begin
					-- cursor over nonclus_keys that are not includes
					select @colstr = ''
					declare mycursor cursor for
						select column_id, column_name, is_descending_key from #nonclus_keys
						where is_included_column = 0
					open mycursor;
					fetch next from mycursor into @column_id, @column_name, @col_descending;
					WHILE @@FETCH_STATUS = 0
					begin
						select @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)' ELSE N'' END + N', ';
						fetch next from mycursor into @column_id, @column_name, @col_descending;
					end
					close mycursor;
					deallocate mycursor;
					
					select @ColsInTree = substring(@colstr, 1, LEN(@colstr) -1);
				
					-- start with the @ColsInTree and add remaining columns not present...
					declare mycursor cursor for
						select column_id, column_name, is_descending_key from #nonclus_keys 
						WHERE is_included_column = 1;
					open mycursor;
					fetch next from mycursor into @column_id, @column_name, @col_descending;
					WHILE @@FETCH_STATUS = 0
					begin
						select @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)' ELSE N'' END + N', ';
						fetch next from mycursor into @column_id, @column_name, @col_descending;
					end
					close mycursor;
					deallocate mycursor;
			
					-- get remaining clustered column as long as they're not already in the nonclustered
					declare mycursor cursor for
						select column_id, column_name, is_descending_key from #clus_keys
						where column_id not in (select column_id from #nonclus_keys)
						order by column_name
					open mycursor;
					fetch next from mycursor into @column_id, @column_name, @col_descending;
					WHILE @@FETCH_STATUS = 0
					begin
						select @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)' ELSE N'' END + N', ';
						fetch next from mycursor into @column_id, @column_name, @col_descending;
					end
					close mycursor;
					deallocate mycursor;	
			
					select @ColsInLeaf = substring(@colstr, 1, LEN(@colstr) -1);
					select @colstr = ''
				
				end
	
				-- Cleanup
				drop table #clus_keys;
				drop table #nonclus_keys;
	
	
			-- </ExposeCols>
			
			IF @indid > 1 AND @is_unique = 0 AND (SELECT is_unique FROM sys.indexes WHERE index_id = 1 AND object_id = @objid) = 0 
				SELECT @ColsInTree = @ColsInTree + N', UNIQUIFIER', @ColsInLeaf = @ColsInLeaf + N', UNIQUIFIER'
			
			IF @indid > 1 AND @is_unique = 1 AND (SELECT is_unique FROM sys.indexes WHERE index_id = 1 AND object_id = @objid) = 0 
				SELECT @ColsInLeaf = @ColsInLeaf + N', UNIQUIFIER'
			
			IF @indid > 1 AND (SELECT COUNT(*) FROM sys.indexes WHERE index_id = 1 AND object_id = @objid) = 0 -- table is a HEAP
			BEGIN
				IF (@is_unique_key = 0)
					SELECT @ColsInTree = @keys + N', RID'
						, @ColsInLeaf = @keys + N', RID' + CASE WHEN @inc_columns IS NOT NULL THEN N', ' + @inc_columns ELSE N'' END
			
				IF (@is_unique_key = 1)
					SELECT @ColsInTree = @keys
						, @ColsInLeaf = @keys + N', RID' + CASE WHEN @inc_columns IS NOT NULL THEN N', ' + @inc_columns ELSE N'' END
			END
				
			-- INSERT ROW FOR INDEX
			
			insert into #spindtab values (@indname, @indid, @ignore_dup_key, @is_unique, @is_hypothetical,
				@is_primary_key, @is_unique_key, @is_disabled, @auto_created, @no_recompute, @groupname, @keys, @filter_definition, @inc_Count, @inc_columns, @ColsInTree, @ColsInLeaf)
	
			-- Next index
	    	fetch ms_crs_ind into @indid, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,
				@is_primary_key, @is_unique_key, @auto_created, @no_recompute, @filter_definition, @is_disabled
		end
		deallocate ms_crs_ind
	
		-- STORE THE REUSLTS IN #FindDupes
		INSERT #FindDupes
		select
			'index_id' = index_id,
			'is_disabled' = is_disabled,
			'index_name' = index_name,
			'index_description' = convert(varchar(210), --bits 16 off, 1, 2, 16777216 on, located on group
					case when index_id = 1 then 'clustered' else 'nonclustered' end
					+ case when ignore_dup_key <>0 then ', ignore duplicate keys' else '' end
					+ case when is_unique=1 then ', unique' else '' end
					+ case when is_hypothetical <>0 then ', hypothetical' else '' end
					+ case when is_primary_key <>0 then ', primary key' else '' end
					+ case when is_unique_key <>0 then ', unique key' else '' end
					+ case when auto_created <>0 then ', auto create' else '' end
					+ case when no_recompute <>0 then ', stats no recompute' else '' end
					+ ' located on ' + groupname),
			'index_keys' = index_keys,
			'included_columns' = inc_columns,
			'filter_definition' = filter_definition,
			'columns_in_tree' = cols_in_tree,
			'columns_in_leaf' = cols_in_leaf
			
		from #spindtab
		order by index_id
	
		-- </sp_SQLSkills_SQL2008_finddupes_helpindex>
	    
	    --SELECT * FROM #FindDupes
		
	    INSERT #DropIndexes
	    SELECT DISTINCT @DBName,
	            @SchemaName, 
	            @TableName, 
	            t1.index_name,
	            N'DROP INDEX ' 
	                + QUOTENAME(@SchemaName, N']') 
	                + N'.' 
	                + QUOTENAME(@TableName, N']') 
	                + N'.' 
	                + t1.index_name 
	    FROM #FindDupes AS t1
	        JOIN #FindDupes AS t2
	            ON t1.columns_in_tree = t2.columns_in_tree
	                AND t1.columns_in_leaf = t2.columns_in_leaf 
	                AND ISNULL(t1.filter_definition, 1) = ISNULL(t2.filter_definition, 1)
	                AND PATINDEX('%unique%', t1.index_description) = PATINDEX('%unique%', t2.index_description)
	                AND t1.index_id > t2.index_id
	                
FetchNextTable:

	    FETCH TableCursor
	        INTO @SchemaName, @TableName
	END
		
	DEALLOCATE TableCursor
	
	-- DISPLAY THE RESULTS
	
	IF (SELECT count(*) FROM #DropIndexes) = 0
	Begin
			Declare @msg varchar(256) = 'Database: ' + @DBName + ' has NO duplicate indexes'
			If @multiTable > 0
				Set @msg = @msg + ' on table ' + @ObjName

			Select @msg as Message
		    RAISERROR(@msg, 10, 0)
	End
	ELSE
	    SELECT * FROM #DropIndexes
	    ORDER BY SchemaName, TableName
	
	return (0)
go

exec sys.sp_MS_marksystemobject 'sp_SQLskills_SQL2008_FindDupes'
go
