--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7031)
				select 0, 'Already correct database version'
            else if (@ver = 7030)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO

PRINT N'Altering [dbo].[netActivityLogAssociatedAllList]...';
GO

ALTER PROCEDURE [dbo].[netActivityLogAssociatedAllList]
(
	@Associations	dbo.StringParameterTable READONLY,
	@StartIndex			BIGINT = NULL,
	@MaxCount			INT = NULL
)
AS            
BEGIN
	DECLARE @Compare AS TABLE(String NVARCHAR(256), CompareString NVARCHAR(257), StringLen INT)
	INSERT INTO @Compare SELECT String, String + '%', LEN(String) FROM (SELECT String = CASE RIGHT(String, 1) WHEN '/' THEN LEFT(String,LEN(String) - 1) ELSE String END FROM @Associations WHERE String IS NOT NULL) X

	DECLARE @MatchAllCount INT = (SELECT COUNT(*) FROM @Compare)

	DECLARE @Ids AS TABLE([ID] [bigint] NOT NULL)
	
	INSERT INTO @Ids
	SELECT pkID FROM (
		SELECT pkID, [From] AS Value, StringLen
			FROM [tblActivityLog]
			JOIN tblActivityLogAssociation ON pkID = [To]
			JOIN @Compare ON [From] LIKE CompareString
			WHERE Deleted = 0
		UNION 
		SELECT pkID, RelatedItem AS Value, StringLen
			FROM [tblActivityLog]
			JOIN @Compare ON RelatedItem LIKE CompareString
			WHERE Deleted = 0
	) Matched WHERE LEN(Value) = StringLen OR SUBSTRING(Value, StringLen + 1, 1) = '/'
	GROUP BY pkID
	HAVING COUNT(pkID) = @MatchAllCount

	DECLARE @TotalCount INT = (SELECT COUNT(*) FROM @Ids)

	SELECT TOP(@MaxCount) [pkID], [Action], [Type], [ChangeDate], [ChangedBy], [LogData], [RelatedItem], [Deleted], @TotalCount AS 'TotalCount'
	FROM [tblActivityLog] al
	JOIN @Ids ids ON al.[pkID] = ids.[ID]
	WHERE [pkID] <= @StartIndex
	ORDER BY [pkID] DESC
END
GO

PRINT N'Altering [dbo].[netActivityLogAssociatedAnyList]...';
GO

ALTER PROCEDURE [dbo].[netActivityLogAssociatedAnyList]
(
	@Associations	 dbo.StringParameterTable READONLY,
	@StartIndex			BIGINT = NULL,
	@MaxCount			INT = NULL
)
AS            
BEGIN
	DECLARE @Compare AS TABLE(String NVARCHAR(256), CompareString NVARCHAR(257), StringLen INT)
	INSERT INTO @Compare SELECT String, String + '%', LEN(String) FROM (SELECT String = CASE RIGHT(String, 1) WHEN '/' THEN LEFT(String,LEN(String) - 1) ELSE String END FROM @Associations WHERE String IS NOT NULL) X

	DECLARE @Ids AS TABLE([ID] [bigint] NOT NULL)

	INSERT INTO @Ids
		SELECT pkID FROM (
			SELECT pkID, [From] AS Value, StringLen 
			FROM [tblActivityLog]
			JOIN tblActivityLogAssociation ON pkID = [To] 
			JOIN @Compare ON [From] LIKE CompareString
			WHERE Deleted = 0
		) Matched WHERE LEN(Value) = StringLen OR SUBSTRING(Value, StringLen + 1, 1) = '/'
	UNION
		SELECT pkID FROM (
			SELECT pkID, RelatedItem AS Value, StringLen
			FROM [tblActivityLog]
			JOIN @Compare ON RelatedItem LIKE CompareString
			WHERE Deleted = 0
		) Matched WHERE LEN(Value) = StringLen OR SUBSTRING(Value, StringLen + 1, 1) = '/'

	DECLARE @TotalCount INT = (SELECT COUNT(*) FROM @Ids)

	SELECT TOP(@MaxCount) [pkID], [Action], [Type], [ChangeDate], [ChangedBy], [LogData], [RelatedItem], [Deleted], @TotalCount AS 'TotalCount'
	FROM [tblActivityLog] al
	JOIN @Ids ids ON al.[pkID] = ids.[ID]
	WHERE [pkID] <= @StartIndex
	ORDER BY [pkID] DESC
END
GO

PRINT N'Altering [dbo].[netActivityLogAssociatedList]...';
GO

ALTER PROCEDURE [dbo].[netActivityLogAssociatedList]
(
	@MatchAll			dbo.StringParameterTable READONLY,
	@MatchAny			dbo.StringParameterTable READONLY,
	@StartIndex			BIGINT = NULL,
	@MaxCount			INT = NULL
)
AS            
BEGIN
	DECLARE @CompareMatchAll AS TABLE(String NVARCHAR(256), CompareString NVARCHAR(257), StringLen INT)
	INSERT INTO @CompareMatchAll SELECT String, String + '%', LEN(String) FROM (SELECT String = CASE RIGHT(String, 1) WHEN '/' THEN LEFT(String,LEN(String) - 1) ELSE String END FROM @MatchAll WHERE String IS NOT NULL) X

	DECLARE @CompareMatchAny AS TABLE(String NVARCHAR(256), CompareString NVARCHAR(257), StringLen INT)
	INSERT INTO @CompareMatchAny SELECT String, String + '%', LEN(String) FROM (SELECT String = CASE RIGHT(String, 1) WHEN '/' THEN LEFT(String,LEN(String) - 1) ELSE String END FROM @MatchAny WHERE String IS NOT NULL) X

	DECLARE @MatchAllCount INT = (SELECT COUNT(*) FROM @CompareMatchAll)

	DECLARE @IdsAll AS TABLE([ID] [bigint] NOT NULL)

	INSERT INTO @IdsAll
	SELECT pkID	FROM (
		SELECT pkID, [From] AS Value, StringLen
			FROM [tblActivityLog]
			JOIN tblActivityLogAssociation ON pkID = [To]
			JOIN @CompareMatchAll ON [From] LIKE CompareString
			WHERE Deleted = 0
		UNION 
		SELECT pkID, RelatedItem AS Value, StringLen
			FROM [tblActivityLog]
			JOIN @CompareMatchAll ON RelatedItem LIKE CompareString
			WHERE Deleted = 0
	) Matched WHERE LEN(Value) = StringLen OR SUBSTRING(Value, StringLen + 1, 1) = '/'
	GROUP BY pkID
	HAVING COUNT(pkID) = @MatchAllCount

	DECLARE @Ids AS TABLE([ID] [bigint] NOT NULL)

	INSERT INTO @Ids
		SELECT pkID FROM (
			SELECT pkID, [From] AS Value, StringLen
			FROM @IdsAll ids
			JOIN [tblActivityLog] ON pkID = ids.ID
			JOIN tblActivityLogAssociation ON pkID = [To]
			JOIN @CompareMatchAny ON [From] LIKE CompareString
			WHERE Deleted = 0
		) Matched WHERE LEN(Value) = StringLen OR SUBSTRING(Value, StringLen + 1, 1) = '/'
	UNION
		SELECT pkID FROM (
			SELECT pkID, RelatedItem AS Value, StringLen
			FROM @IdsAll ids
			JOIN [tblActivityLog] ON pkID = ids.ID
			JOIN @CompareMatchAny ON RelatedItem LIKE CompareString
			WHERE Deleted = 0
		) Matched WHERE LEN(Value) = StringLen OR SUBSTRING(Value, StringLen + 1, 1) = '/'

	DECLARE @TotalCount INT = (SELECT COUNT(*) FROM @Ids)

	SELECT TOP(@MaxCount) [pkID], [Action], [Type], [ChangeDate], [ChangedBy], [LogData], [RelatedItem], [Deleted], @TotalCount AS 'TotalCount'
	FROM [tblActivityLog] al
	JOIN @Ids ids ON al.[pkID] = ids.[ID]
	WHERE [pkID] <= @StartIndex
	ORDER BY [pkID] DESC
END
GO

PRINT N'Altering [dbo].[netActivityLogAssociationDeleteRelated]...';
GO

ALTER PROCEDURE [dbo].[netActivityLogAssociationDeleteRelated]
(
	@AssociatedItem	[nvarchar](255),
	@RelatedItem	[nvarchar](255)
)
AS            
BEGIN
	DECLARE @RelatedItemCompare NVARCHAR(256) = CASE RIGHT(@RelatedItem, 1) WHEN '/' THEN LEFT(@RelatedItem, LEN(@RelatedItem) - 1) ELSE @RelatedItem END
	DECLARE @RelatedItemLike NVARCHAR(256) = @RelatedItemCompare + '%'
	DECLARE @RelatedItemLength INT = LEN(@RelatedItemLike)

	DELETE FROM [tblActivityLogAssociation] 
	FROM [tblActivityLogAssociation] AS TCLA INNER JOIN [tblActivityLog] AS TCL ON TCLA.[To] = TCL.pkID
	WHERE (TCLA.[From] = @AssociatedItem AND TCL.[RelatedItem] LIKE @RelatedItemLike AND (TCL.[RelatedItem] = @RelatedItemCompare OR SUBSTRING(TCL.[RelatedItem], @RelatedItemLength, 1) = '/'))
	OR (TCLA.[From] LIKE @RelatedItemLike AND TCL.[RelatedItem] = @AssociatedItem AND (TCLA.[From] = @RelatedItemCompare OR SUBSTRING(TCLA.[From], @RelatedItemLength, 1) = '/'))
END
GO

PRINT N'Altering [dbo].[netActivityLogGetAssociations]...';
GO

ALTER PROCEDURE [dbo].[netActivityLogGetAssociations]
(
	@Id	BIGINT
)
AS            
BEGIN
		SELECT RelatedItem AS Uri
			FROM [tblActivityLog] 
			WHERE 
				@Id = pkID AND
				RelatedItem IS NOT NULL 
		UNION
		SELECT [From] AS Uri
			FROM [tblActivityLogAssociation] 
			WHERE 
				[To] = @Id AND
				[From] IS NOT NULL 
END
GO

PRINT N'Update complete.';

GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7031

GO
PRINT N'Update complete.';
GO
