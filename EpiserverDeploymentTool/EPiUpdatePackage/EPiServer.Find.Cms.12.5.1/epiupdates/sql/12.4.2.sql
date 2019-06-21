--beginvalidatingquery 
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'tblFindDatabaseVersion') 
    BEGIN 
    declare @major int = 12, @minor int = 4, @patch int = 2   
    IF EXISTS (SELECT 1 FROM dbo.tblFindDatabaseVersion WHERE Major = @major AND Minor = @minor AND Patch = @patch) 
        select 0,'Already correct database version' 
    ELSE 
        select 1, 'Upgrading database' 
    END 
ELSE 
    select -1, 'Not an EPiServer database with Find' 
--endvalidatingquery 
 
GO 
 
ALTER TABLE dbo.tblFindIndexQueue ADD LastRead datetime
 
GO
 
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id (N'[dbo].[findIndexQueueLoadItems]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1) DROP PROCEDURE [dbo].[findIndexQueueLoadItems]
 
GO 
 
CREATE PROCEDURE [dbo].[findIndexQueueLoadItems]
(
    @items INT,
    @currentTime datetime,
    @acceptLastReadOlderThan datetime
)
AS 

BEGIN
	
	SET NOCOUNT ON
	
	DECLARE @hashes TABLE(tempHash INT);

	INSERT INTO @hashes 
		SELECT TOP (@items) Hash FROM tblFindIndexQueue WHERE (LastRead IS NULL OR LastRead < @acceptLastReadOlderThan) ORDER BY TimeStamp

	UPDATE tblFindIndexQueue SET LastRead = @currentTime WHERE Hash in(SELECT tempHash FROM @hashes)
	SELECT Action, [Cascade], EnableLanguageFilter, Item, [Language], TimeStamp, Hash FROM tblFindIndexQueue WHERE Hash in(SELECT tempHash FROM @hashes)
END 
 
GO
 
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id (N'[dbo].[findIndexQueueLoadAll]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1) DROP PROCEDURE [dbo].[findIndexQueueLoadAll]
 
GO 
 
CREATE PROCEDURE [dbo].[findIndexQueueLoadAll]
(
    @currentTime datetime
)
 AS 

BEGIN
	
	SET NOCOUNT ON
	
	UPDATE tblFindIndexQueue SET LastRead = @currentTime
	SELECT Action, [Cascade], EnableLanguageFilter, Item, Language, TimeStamp, Hash FROM tblFindIndexQueue ORDER BY TimeStamp

END 
 
GO
 
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id (N'[dbo].[findIndexQueueSave]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1) DROP PROCEDURE [dbo].[findIndexQueueSave]
 
GO 
 
CREATE PROCEDURE [dbo].[findIndexQueueSave]
(
    @action int,
	@cascade bit,
	@enableLanguageFilter bit,
	@item nvarchar(255),
	@itemlanguage nvarchar(255),
	@timeStamp datetime,
	@hash int
)
AS
 
BEGIN
	SET NOCOUNT ON
	
	if not exists(select * from tblFindIndexQueue where Hash=@hash AND LastRead IS NULL) 
		BEGIN 
			insert into tblFindIndexQueue(Action, [Cascade], EnableLanguageFilter, Item, [Language], TimeStamp, [Hash]) values(@action, @cascade, @enableLanguageFilter, @item, @itemlanguage, @timeStamp, @hash) 
		END 
	else
		BEGIN
			update tblFindIndexQueue set TimeStamp = @timeStamp where Hash=@hash
		END
END 
 
GO 
 
insert into tblFindDatabaseVersion(Major, Minor, Patch) values(12,4,2)

GO

PRINT N'Update complete.';