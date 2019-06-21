--beginvalidatingquery 
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'tblFindDatabaseVersion') 
    BEGIN 
    declare @major int = 12, @minor int = 2, @patch int = 8    
    IF EXISTS (SELECT 1 FROM dbo.tblFindDatabaseVersion WHERE Major = @major AND Minor = @minor AND Patch = @patch) 
        select 0,'Already correct database version' 
    ELSE 
        select 1, 'Upgrading database' 
    END 
ELSE 
    select -1, 'Not an EPiServer database with Find' 
--endvalidatingquery 
 
GO 

CREATE TABLE [dbo].[tblFindIndexQueue](
	[Action] [smallint] NOT NULL,
	[Cascade] [bit] NOT NULL,
	[EnableLanguageFilter] [bit] NOT NULL,
	[Item] [nvarchar](255) NOT NULL,
	[Language] [nvarchar](255) NULL,
	[TimeStamp] [datetime] NOT NULL,
	[Hash] [int] NULL
) ON [PRIMARY]

GO 

CREATE PROCEDURE [dbo].[findIndexQueueLoadAll]
 AS 

BEGIN
	
	SET NOCOUNT ON
	
	select Action, [Cascade], EnableLanguageFilter, Item, Language, TimeStamp, Hash from tblFindIndexQueue ORDER BY TimeStamp

END



GO 



CREATE PROCEDURE [dbo].[findIndexQueueLoadItems]
(
    @items INT
)
AS 

BEGIN
	
	SET NOCOUNT ON
	
	select top (@items) Action, [Cascade], EnableLanguageFilter, Item, [Language], TimeStamp, Hash from tblFindIndexQueue ORDER BY TimeStamp

END 


GO 


CREATE PROCEDURE [dbo].[findIndexQueueDeleteItem]
(
    @hash INT
)
AS 

BEGIN

	SET NOCOUNT ON
	
	delete from tblFindIndexQueue where [Hash] = @hash 

END 

GO 



CREATE PROCEDURE [dbo].[findIndexQueueDeleteItems]
(
    @hashes findIDTable READONLY
)
AS
 

BEGIN
	
	SET NOCOUNT ON
	
	delete from tblFindIndexQueue where [Hash] in(select [ID] from @hashes)

END 



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
	
	if not exists(select * from tblFindIndexQueue where Hash=@hash) 
	BEGIN 

		insert into tblFindIndexQueue(Action, [Cascade], EnableLanguageFilter, Item, [Language], TimeStamp, [Hash]) values(@action, @cascade, @enableLanguageFilter, @item, @itemlanguage, @timeStamp, @hash) 
	
	END 

END 


GO

insert into tblFindDatabaseVersion(Major, Minor, Patch) values(12,2,8)

GO

PRINT N'Update complete.';