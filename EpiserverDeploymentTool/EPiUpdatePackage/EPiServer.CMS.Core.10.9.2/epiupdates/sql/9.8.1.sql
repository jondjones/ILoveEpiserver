--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7034)
				select 0, 'Already correct database version'
            else if (@ver = 7033)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
GO

PRINT N'Creating [dbo].[BigTableDeleteItemInternalTable]...';
GO

CREATE TYPE [dbo].[BigTableDeleteItemInternalTable] AS TABLE(
	[Id] [bigint] NULL,
	[NestLevel] [int] NULL,
	[ObjectPath] [varchar](MAX) NULL
)
GO
PRINT N'Creating [dbo].[editDeletePageInternalTable]...';
GO

CREATE TYPE [dbo].[editDeletePageInternalTable] AS TABLE(
	[pkID] [int] PRIMARY KEY,
	[PageGUID] [uniqueidentifier] NULL
)
GO

PRINT N'Altering [dbo].[BigTableDeleteAll]...';
GO

ALTER PROCEDURE [dbo].[BigTableDeleteAll]
@ViewName nvarchar(4000)
AS
BEGIN
	DECLARE @deletes AS BigTableDeleteItemInternalTable;
	INSERT INTO @deletes(Id, NestLevel, ObjectPath)
	EXEC ('SELECT [StoreId], 1, ''/'' + CAST([StoreId] AS VARCHAR) + ''/'' FROM ' + @ViewName)

	EXEC sp_executesql N'BigTableDeleteItemInternal @deletes, 1', N'@deletes BigTableDeleteItemInternalTable READONLY',@deletes 
END
GO

PRINT N'Altering [dbo].[BigTableDeleteExcessReferences]...';
GO

ALTER PROCEDURE [dbo].[BigTableDeleteExcessReferences]
	@Id bigint,
	@PropertyName nvarchar(75),
	@StartIndex int
AS
BEGIN
BEGIN TRAN
	IF @StartIndex > -1
	BEGIN
		-- Creates temporary store with id's of references that has no other reference
		DECLARE @deletes AS BigTableDeleteItemInternalTable;
		
		INSERT INTO @deletes(Id, NestLevel, ObjectPath)
		SELECT DISTINCT R1.RefIdValue, 1, '/' + CAST(R1.RefIdValue AS VARCHAR) + '/' FROM tblBigTableReference AS R1
		LEFT OUTER JOIN tblBigTableReference AS R2 ON R1.RefIdValue = R2.pkId
		WHERE R1.pkId = @Id AND R1.PropertyName = @PropertyName AND R1.[Index] >= @StartIndex AND 
				R1.RefIdValue IS NOT NULL AND R2.RefIdValue IS NULL
		
		-- Remove reference on main store
		DELETE FROM tblBigTableReference WHERE pkId = @Id and PropertyName = @PropertyName and [Index] >= @StartIndex
		
		IF((select count(*) from @deletes) > 0)
		BEGIN
			EXEC sp_executesql N'BigTableDeleteItemInternal @deletes', N'@deletes BigTableDeleteItemInternalTable READONLY',@deletes 
		END

	END
	ELSE
		-- Remove reference on main store
		DELETE FROM tblBigTableReference WHERE pkId = @Id and PropertyName = @PropertyName and [Index] >= @StartIndex
COMMIT TRAN

END
GO

PRINT N'Altering [dbo].[BigTableDeleteItem]...';
GO

ALTER PROCEDURE [dbo].[BigTableDeleteItem]
@StoreId BIGINT = NULL,
@ExternalId uniqueidentifier = NULL
AS
BEGIN
	IF @StoreId IS NULL
	BEGIN
		SELECT @StoreId = pkId FROM tblBigTableIdentity WHERE [Guid] = @ExternalId
	END
	IF @StoreId IS NULL RAISERROR(N'No object exists for the unique identifier passed', 1, 1)

	DECLARE @deletes AS BigTableDeleteItemInternalTable;
	INSERT INTO @deletes(Id, NestLevel, ObjectPath) VALUES(@StoreId, 1, '/' + CAST(@StoreId AS varchar) + '/')

	EXEC sp_executesql N'BigTableDeleteItemInternal @deletes', N'@deletes BigTableDeleteItemInternalTable READONLY',@deletes 
END
GO

PRINT N'Altering [dbo].[BigTableDeleteItemInternal]...';
GO

ALTER PROCEDURE [dbo].[BigTableDeleteItemInternal]
@TVP BigTableDeleteItemInternalTable READONLY,
@forceDelete bit = 0
AS
BEGIN
	DECLARE @deletes AS BigTableDeleteItemInternalTable
	INSERT INTO @deletes SELECT * FROM @TVP

	DECLARE @nestLevel int
	SET @nestLevel = 1
	WHILE @@ROWCOUNT > 0
	BEGIN
		SET @nestLevel = @nestLevel + 1
		-- insert all items contained in the ones matching the _previous_ nestlevel and give them _this_ nestLevel
		-- exclude those items that are also referred by some other item not already in @deletes
		-- IMPORTANT: Make sure that this insert is the last statement that can affect @@ROWCOUNT in the while-loop
		INSERT INTO @deletes(Id, NestLevel, ObjectPath)
		SELECT DISTINCT RefIdValue, @nestLevel, deletes.ObjectPath + '/' + CAST(RefIdValue AS VARCHAR) + '/'
		FROM tblBigTableReference R1
		INNER JOIN @deletes deletes ON deletes.Id=R1.pkId
		WHERE deletes.NestLevel=@nestLevel-1
		AND RefIdValue NOT IN(SELECT Id FROM @deletes)
	END 
	DELETE @deletes FROM @deletes deletes
	INNER JOIN 
	(
		SELECT innerDelete.Id
		FROM @deletes as innerDelete
		INNER JOIN tblBigTableReference ON tblBigTableReference.RefIdValue=innerDelete.Id
		WHERE NOT EXISTS(SELECT * FROM @deletes deletes WHERE deletes.Id=tblBigTableReference.pkId)
	) ReferencedObjects ON deletes.ObjectPath LIKE '%/' + CAST(ReferencedObjects.Id AS VARCHAR) + '/%'
	WHERE @forceDelete = 0 OR deletes.NestLevel > 1

	-- Go through each big table and create sql to delete any rows associated with the item being deleted
	DECLARE @sql NVARCHAR(MAX) = ''
	DECLARE @tableName NVARCHAR(128)
	DECLARE tableNameCursor CURSOR READ_ONLY 
	
	FOR SELECT DISTINCT TableName FROM tblBigTableStoreConfig WHERE TableName IS NOT NULL				
	OPEN tableNameCursor
	FETCH NEXT FROM tableNameCursor INTO @tableName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sql = @sql + 'DELETE t1 FROM ' + @tableName  +  ' t1 JOIN @deletes t2 ON t1.pkId = t2.Id;' + CHAR(13)
		FETCH NEXT FROM tableNameCursor INTO @tableName
	END
	CLOSE tableNameCursor
	DEALLOCATE tableNameCursor 			

	BEGIN TRAN
    DELETE t1 FROM tblBigTableReference t1 JOIN @deletes t2 ON t1.RefIdValue = t2.Id
    DELETE t1 FROM tblBigTableReference t1 JOIN @deletes t2 ON t1.pkId = t2.Id
    EXEC sp_executesql @sql, N'@deletes BigTableDeleteItemInternalTable READONLY',@deletes 
    DELETE t1 FROM tblBigTableIdentity t1 JOIN @deletes t2 ON t1.pkId = t2.Id	 
	COMMIT TRAN
END
GO

PRINT N'Altering [dbo].[editDeleteChilds]...';
GO

ALTER PROCEDURE [dbo].[editDeleteChilds]
(
    @PageID			INT,
    @ForceDelete	INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON
    DECLARE @retval INT

	DECLARE @pages AS editDeletePageInternalTable
	
	INSERT INTO @pages (pkID) 
	SELECT 
		fkChildID 
	FROM 
		tblTree 
	WHERE fkParentID=@PageID

	UPDATE @pages 
		SET PageGUID = tblPage.PageGUID
	FROM tblPage INNER JOIN @pages pages ON pages.pkID=tblPage.pkID

	DECLARE @sql NVARCHAR(200) = N'EXEC @retval=editDeletePageInternal @pages, @PageID=@PageID, @ForceDelete=@ForceDelete'
	DECLARE @params NVARCHAR(200) = N'@pages editDeletePageInternalTable READONLY, @PageID INT, @ForceDelete INT, @retval int OUTPUT'
	EXEC sp_executesql @sql, @params, @pages, @PageID, @ForceDelete, @retval=@retval OUTPUT

	UPDATE tblContent SET IsLeafNode = 1 WHERE pkID=@PageID
        
	RETURN @retval
END
GO

PRINT N'Altering [dbo].[editDeleteChildsCheck]...';
GO

ALTER PROCEDURE [dbo].[editDeleteChildsCheck]
(
	@PageID			INT
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	/* Get all pages to delete (all childs of PageID) */
	DECLARE @pages AS editDeletePageInternalTable

	INSERT INTO @pages (pkID) 
	SELECT 
		fkChildID 
	FROM 
		tblTree 
	WHERE fkParentID=@PageID
	
	UPDATE @pages 
		SET PageGUID = tblPage.PageGUID
	FROM tblPage INNER JOIN @pages pages ON pages.pkID=tblPage.pkID
	
	EXEC sp_executesql N'EXEC editDeletePageCheckInternal @pages', N'@pages editDeletePageInternalTable READONLY', @pages

	RETURN 0
END
GO

PRINT N'Altering [dbo].[editDeletePage]...';
GO

ALTER PROCEDURE [dbo].[editDeletePage]
(
	@PageID			INT,
	@ForceDelete	INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @retval INT
	DECLARE @ParentID INT

	/* Get all pages to delete (= PageID and all its childs) */
	DECLARE @pages AS editDeletePageInternalTable

	INSERT INTO @pages (pkID) 
	SELECT 
		fkChildID 
	FROM 
		tblTree 
	WHERE fkParentID=@PageID
	UNION
	SELECT @PageID
	
	UPDATE @pages 
		SET PageGUID = tblPage.PageGUID
	FROM tblPage INNER JOIN @pages pages ON pages.pkID=tblPage.pkID
	
	SELECT @ParentID=fkParentID FROM tblPage WHERE pkID=@PageID
				
	DECLARE @sql NVARCHAR(200) = N'EXEC @retval=editDeletePageInternal @pages, @PageID=@PageID, @ForceDelete=@ForceDelete'
	DECLARE @params NVARCHAR(200) = N'@pages editDeletePageInternalTable READONLY, @PageID INT, @ForceDelete INT, @retval int OUTPUT'
	EXEC sp_executesql @sql, @params, @pages, @PageID, @ForceDelete, @retval=@retval OUTPUT

	IF NOT EXISTS(SELECT * FROM tblContent WHERE fkParentID=@ParentID)
		UPDATE tblContent SET IsLeafNode = 1 WHERE pkID=@ParentID
	
	RETURN @retval
END
GO

PRINT N'Altering [dbo].[editDeletePageCheck]...';
GO

ALTER PROCEDURE [dbo].[editDeletePageCheck]
(
	@PageID			INT,
	@IncludeDecendents BIT
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	/* Get all pages to delete (= PageID and all its childs) */
	DECLARE @pages AS editDeletePageInternalTable

	INSERT INTO @pages (pkID) 
	SELECT @PageID
	IF @IncludeDecendents = 1
	BEGIN
		INSERT INTO @pages (pkID) 
		SELECT 
			fkChildID 
		FROM 
			tblTree 
		WHERE fkParentID=@PageID
	END
	
	UPDATE @pages 
		SET PageGUID = tblPage.PageGUID
	FROM tblPage INNER JOIN @pages pages ON pages.pkID=tblPage.pkID
	
	EXEC sp_executesql N'EXEC editDeletePageCheckInternal @pages', N'@pages editDeletePageInternalTable READONLY', @pages
END
GO

PRINT N'Altering [dbo].[editDeletePageCheckInternal]...';
GO

ALTER PROCEDURE [dbo].[editDeletePageCheckInternal]
(@pages editDeletePageInternalTable READONLY) 
AS
BEGIN
	SET NOCOUNT ON

	SELECT
		tblPageLanguage.fkLanguageBranchID AS OwnerLanguageID,
		NULL AS ReferencedLanguageID,
		tblPageLanguage.fkPageID AS OwnerID, 
		tblPageLanguage.Name As OwnerName,
		PageLink As ReferencedID,
		tpl.Name AS ReferencedName,
		0 AS ReferenceType
	FROM 
		tblProperty 
	INNER JOIN 
		tblPage ON tblProperty.fkPageID=tblPage.pkID
	INNER JOIN 
		tblPageLanguage ON tblPageLanguage.fkPageID=tblPage.pkID
	INNER JOIN
		tblPage AS tp ON PageLink=tp.pkID
	INNER JOIN
		tblPageLanguage AS tpl ON tpl.fkPageID=tp.pkID
	WHERE 
		(tblProperty.fkPageID NOT IN (SELECT pkID FROM @pages)) AND
		(PageLink IN (SELECT pkID FROM @pages)) AND
		tblPage.Deleted=0 AND
		tblPageLanguage.fkLanguageBranchID=tblProperty.fkLanguageBranchID AND
		tpl.fkLanguageBranchID=tp.fkMasterLanguageBranchID
	
	UNION
	
	SELECT
		tblPageLanguage.fkLanguageBranchID AS OwnerLanguageID,
		NULL AS ReferencedLanguageID,    
		tblPageLanguage.fkPageID AS OwnerID,
		tblPageLanguage.Name As OwnerName,
		tp.pkID AS ReferencedID,
		tpl.Name AS ReferencedName,
		1 AS ReferenceType
	FROM
		tblPageLanguage
	INNER JOIN
		tblPage ON tblPage.pkID=tblPageLanguage.fkPageID
	INNER JOIN
		tblPage AS tp ON tblPageLanguage.PageLinkGUID = tp.PageGUID
	INNER JOIN
		tblPageLanguage AS tpl ON tpl.fkPageID=tp.pkID
	WHERE
		(tblPageLanguage.fkPageID NOT IN (SELECT pkID FROM @pages)) AND
		(tblPageLanguage.PageLinkGUID IN (SELECT PageGUID FROM @pages)) AND
		tblPage.Deleted=0 AND
		tpl.fkLanguageBranchID=tp.fkMasterLanguageBranchID
	
	UNION
	
	SELECT
		tblContentSoftlink.OwnerLanguageID AS OwnerLanguageID,
		tblContentSoftlink.ReferencedLanguageID AS ReferencedLanguageID,
		PLinkFrom.pkID AS OwnerID,
		PLinkFromLang.Name  As OwnerName,
		PLinkTo.pkID AS ReferencedID,
		PLinkToLang.Name AS ReferencedName,
		1 AS ReferenceType
	FROM
		tblContentSoftlink
	INNER JOIN
		tblPage AS PLinkFrom ON PLinkFrom.pkID=tblContentSoftlink.fkOwnerContentID
	INNER JOIN
		tblPageLanguage AS PLinkFromLang ON PLinkFromLang.fkPageID=PLinkFrom.pkID
	INNER JOIN
		tblPage AS PLinkTo ON PLinkTo.PageGUID=tblContentSoftlink.fkReferencedContentGUID
	INNER JOIN
		tblPageLanguage AS PLinkToLang ON PLinkToLang.fkPageID=PLinkTo.pkID
	WHERE
		(PLinkFrom.pkID NOT IN (SELECT pkID FROM @pages)) AND
		(PLinkTo.pkID IN (SELECT pkID FROM @pages)) AND
		PLinkFrom.Deleted=0 AND
		PLinkFromLang.fkLanguageBranchID=PLinkFrom.fkMasterLanguageBranchID AND
		PLinkToLang.fkLanguageBranchID=PLinkTo.fkMasterLanguageBranchID
		
	UNION
	
	SELECT
		tblPageLanguage.fkLanguageBranchID AS OwnerLanguageID,
		NULL AS ReferencedLanguageID,
		tblPage.pkID AS OwnerID,
		tblPageLanguage.Name  As OwnerName,
		tp.pkID AS ReferencedID,
		tpl.Name AS ReferencedName,
		2 AS ReferenceType
	FROM
		tblPage
	INNER JOIN 
		tblPageLanguage ON tblPageLanguage.fkPageID=tblPage.pkID
	INNER JOIN
		tblPage AS tp ON tblPage.ArchivePageGUID=tp.PageGUID
	INNER JOIN
		tblPageLanguage AS tpl ON tpl.fkPageID=tp.pkID
	WHERE
		(tblPage.pkID NOT IN (SELECT pkID FROM @pages)) AND
		(tblPage.ArchivePageGUID IN (SELECT PageGUID FROM @pages)) AND
		tblPage.Deleted=0 AND
		tpl.fkLanguageBranchID=tp.fkMasterLanguageBranchID AND
		tblPageLanguage.fkLanguageBranchID=tblPage.fkMasterLanguageBranchID
	UNION
	
	SELECT 
		tblPageLanguage.fkLanguageBranchID AS OwnerLanguageID,
		NULL AS ReferencedLanguageID,
		tblPage.pkID AS OwnerID, 
		tblPageLanguage.Name  As OwnerName,
		tblPageTypeDefault.fkArchivePageID AS ReferencedID,
		tblPageType.Name AS ReferencedName,
		3 AS ReferenceType
	FROM 
		tblPageTypeDefault
	INNER JOIN
	   tblPageType ON tblPageTypeDefault.fkPageTypeID=tblPageType.pkID
	INNER JOIN
		tblPage ON tblPageTypeDefault.fkArchivePageID=tblPage.pkID
	INNER JOIN 
		tblPageLanguage ON tblPageLanguage.fkPageID=tblPage.pkID
	WHERE 
		tblPageTypeDefault.fkArchivePageID IN (SELECT pkID FROM @pages) AND
		tblPageLanguage.fkLanguageBranchID=tblPage.fkMasterLanguageBranchID
	ORDER BY
	   ReferenceType
		
	RETURN 0
	
END
GO

PRINT N'Altering [dbo].[editDeletePageInternal]...';
GO

ALTER PROCEDURE [dbo].[editDeletePageInternal]
(
    @pages editDeletePageInternalTable READONLY,
    @PageID INT,
    @ForceDelete INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

-- STRUCTURE
	
	-- Make sure we dump structure and features like fetch data before we start off repairing links for pages that should not get deleted
	UPDATE 
	    tblPage 
	SET 
	    fkParentID = NULL,
	    ArchivePageGUID=NULL 
	WHERE 
	    pkID IN ( SELECT pkID FROM @pages )
	UPDATE 
	    tblContentLanguage
	SET 
	    Version = NULL 
	WHERE 
	    fkContentID IN ( SELECT pkID FROM @pages )
	    
	UPDATE 
	    tblWorkPage 
	SET 
	    fkMasterVersionID=NULL,
	    PageLinkGUID=NULL,
	    ArchivePageGUID=NULL 
	WHERE 
	    fkPageID IN ( SELECT pkID FROM @pages )
-- VERSION DATA
	-- Delete page links, archiving and fetch data pointing to us from external pages
	DELETE FROM 
	    tblWorkProperty 
	WHERE 
	    PageLink IN ( SELECT pkID FROM @pages )
	    
	UPDATE 
	    tblWorkPage 
	SET 
	    ArchivePageGUID = NULL 
	WHERE 
	    ArchivePageGUID IN ( SELECT PageGUID FROM @pages )
	    
	UPDATE 
	    tblWorkPage 
	SET 
	    PageLinkGUID = NULL, 
	    LinkType=0,
	    LinkURL=
		(
			SELECT TOP 1 
			      '~/link/' + CONVERT(NVARCHAR(32),REPLACE((select top 1 PageGUID FROM tblPage where tblPage.pkID = tblWorkPage.fkPageID),'-','')) + '.aspx'
			FROM 
			    tblPageType
			WHERE 
			    tblPageType.pkID=(SELECT fkPageTypeID FROM tblPage WHERE tblPage.pkID=tblWorkPage.fkPageID)
		)
	 WHERE 
	    PageLinkGUID IN ( SELECT PageGUID FROM @pages )
	
	-- Remove workproperties,workcategories and finally the work versions themselves
	DELETE FROM 
	    tblWorkProperty 
	WHERE 
	    fkWorkPageID IN ( SELECT pkID FROM tblWorkPage WHERE fkPageID IN ( SELECT pkID FROM @pages ) )
	    
	DELETE FROM 
	    tblWorkCategory 
	WHERE 
	    fkWorkPageID IN ( SELECT pkID FROM tblWorkPage WHERE fkPageID IN ( SELECT pkID FROM @pages ) )
	    
	DELETE FROM 
	    tblWorkPage 
	WHERE 
	    fkPageID IN ( SELECT pkID FROM @pages )
-- PUBLISHED PAGE DATA
	IF (@ForceDelete IS NOT NULL)
	BEGIN
		DELETE FROM 
		    tblProperty 
		WHERE 
		    PageLink IN (SELECT pkID FROM @pages)
	END
	ELSE
	BEGIN
		/* Default action: Only delete references from pages in wastebasket */
		DELETE FROM 
			tblProperty
		FROM 
		    tblProperty AS P
		INNER JOIN 
		    tblPage ON P.fkPageID=tblPage.pkID
		WHERE
			tblPage.Deleted=1 AND
			P.PageLink IN (SELECT pkID FROM @pages)
	END
	DELETE FROM 
	    tblPropertyDefault 
	WHERE 
	    PageLink IN ( SELECT pkID FROM @pages )
	    
	UPDATE 
	    tblPage 
	SET 
	    ArchivePageGUID = NULL 
	WHERE 
	    ArchivePageGUID IN ( SELECT PageGUID FROM @pages )
	-- Remove fetch data from any external pages pointing to us
	UPDATE 
	    tblPageLanguage 
	SET     
	    PageLinkGUID = NULL, 
	    FetchData=0,
	    LinkURL=
		(
			SELECT TOP 1 
		      '~/link/' + CONVERT(NVARCHAR(32),REPLACE((select top 1 PageGUID FROM tblPage where tblPage.pkID = tblPageLanguage.fkPageID),'-','')) + '.aspx'
			FROM 
			    tblPageType
			WHERE 
			    tblPageType.pkID=(SELECT tblPage.fkPageTypeID FROM tblPage WHERE tblPage.pkID=tblPageLanguage.fkPageID)
		)
	 WHERE 
	    PageLinkGUID IN ( SELECT PageGUID FROM @pages )
	-- Remove ALC, categories and the properties
	DELETE FROM 
	    tblCategoryPage 
	WHERE 
	    fkPageID IN ( SELECT pkID FROM @pages )
	    
	DELETE FROM 
	    tblProperty 
	WHERE 
	    fkPageID IN ( SELECT pkID FROM @pages )
	    
	DELETE FROM 
	    tblContentAccess 
	WHERE 
	    fkContentID IN ( SELECT pkID FROM @pages )
-- KEYWORDS AND INDEXING
	
	DELETE FROM 
	    tblContentSoftlink
	WHERE 
	    fkOwnerContentID IN ( SELECT pkID FROM @pages )
-- PAGETYPES
	    
	UPDATE 
	    tblPageTypeDefault 
	SET 
	    fkArchivePageID=NULL 
	WHERE fkArchivePageID IN (SELECT pkID FROM @pages)
-- PAGE/TREE
	DELETE FROM 
	    tblTree 
	WHERE 
	    fkChildID IN ( SELECT pkID FROM @pages )
	    
	DELETE FROM 
	    tblTree 
	WHERE 
	    fkParentID IN ( SELECT pkID FROM @pages )
	    
	DELETE FROM 
	    tblPageLanguage 
	WHERE 
	    fkPageID IN ( SELECT pkID FROM @pages )
	    
	DELETE FROM 
	    tblPageLanguageSetting 
	WHERE 
	    fkPageID IN ( SELECT pkID FROM @pages )
   
	DELETE FROM
	    tblPage 
	WHERE 
	    pkID IN ( SELECT pkID FROM @pages )
END
GO

PRINT N'Altering [dbo].[netActivityLogTruncate]...';
GO
ALTER PROCEDURE [dbo].[netActivityLogTruncate]
(
	@MaxRows BIGINT = NULL,
	@BeforeEntry BIGINT = NULL,
	@CreatedBefore DATETIME = NULL,
	@PreservedRelation  nvarchar(255) = NULL
)
AS
BEGIN	
	IF (@PreservedRelation IS NOT NULL)
	BEGIN
			DECLARE @PreservedRelationLike NVARCHAR(256) = @PreservedRelation + '%'
			IF (@MaxRows IS NOT NULL)
			BEGIN
				DELETE TOP(@MaxRows) L FROM [tblActivityLog] as L LEFT OUTER JOIN [tblActivityLogAssociation] as A ON L.pkID = A.[To]
				WHERE (((@BeforeEntry IS NULL) OR (pkID < @BeforeEntry)) AND ((@CreatedBefore IS NULL) OR (ChangeDate < @CreatedBefore))
				AND ((A.[From] IS NULL OR A.[From] NOT LIKE @PreservedRelationLike) AND (L.RelatedItem IS NULL OR L.RelatedItem NOT LIKE @PreservedRelationLike)))
			END
			ELSE
			BEGIN
				DELETE L FROM [tblActivityLog] as L LEFT OUTER JOIN [tblActivityLogAssociation] as A ON L.pkID = A.[To]
				WHERE (((@BeforeEntry IS NULL) OR (pkID < @BeforeEntry)) AND ((@CreatedBefore IS NULL) OR (ChangeDate < @CreatedBefore))
				AND ((A.[From] IS NULL OR A.[From] NOT LIKE @PreservedRelationLike) AND (L.RelatedItem IS NULL OR L.RelatedItem NOT LIKE @PreservedRelationLike)))
			END
	END
	ELSE
	BEGIN
		IF (@MaxRows IS NOT NULL)
		BEGIN
			DELETE TOP(@MaxRows) FROM [tblActivityLog] 
			WHERE ((@BeforeEntry IS NULL) OR (pkID < @BeforeEntry)) AND ((@CreatedBefore IS NULL) OR (ChangeDate < @CreatedBefore))
		END
		ELSE
		BEGIN
			DELETE FROM [tblActivityLog] 
			WHERE ((@BeforeEntry IS NULL) OR (pkID < @BeforeEntry)) AND ((@CreatedBefore IS NULL) OR (ChangeDate < @CreatedBefore))
		END
	END

	RETURN @@ROWCOUNT
END
GO

PRINT N'Altering [dbo].[netCategoryStringToTable]...';
GO

ALTER PROCEDURE dbo.netCategoryStringToTable
(
	@CategoryList	NVARCHAR(2000)
)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE		@DotPos INT
	DECLARE		@Category NVARCHAR(255)

	DECLARE @CategoryResult TABLE(fkCategoryID INT)
	
	WHILE (DATALENGTH(@CategoryList) > 0)
	BEGIN
		SET @DotPos = CHARINDEX(N',', @CategoryList)
		IF @DotPos > 0
			SET @Category = LEFT(@CategoryList,@DotPos-1)
		ELSE
		BEGIN
			SET @Category = @CategoryList
			SET @CategoryList = NULL
		END
		IF LEN(@Category) > 0 AND @Category NOT LIKE '%[^0-9]%'
		    INSERT INTO @CategoryResult SELECT pkID FROM tblCategory WHERE pkID = CAST(@Category AS INT)
		ELSE
			INSERT INTO @CategoryResult SELECT pkID FROM tblCategory WHERE CategoryName = @Category
			
		IF (DATALENGTH(@CategoryList) > 0)
			SET @CategoryList = SUBSTRING(@CategoryList,@DotPos+1,255)
	END
	SELECT * FROM @CategoryResult
END
GO

PRINT N'Altering [dbo].[netPropertySearchCategory]...';
GO

ALTER PROCEDURE dbo.netPropertySearchCategory
(
	@PageID			INT,
	@PropertyName 	NVARCHAR(255),
	@Equals			BIT = 0,
	@NotEquals		BIT = 0,
	@CategoryList	NVARCHAR(2000) = NULL,
	@LanguageBranch	NCHAR(17) = NULL
)
AS
BEGIN
	DECLARE @LangBranchID NCHAR(17);
	SELECT @LangBranchID=pkID FROM tblLanguageBranch WHERE LanguageID=@LanguageBranch
	IF @LangBranchID IS NULL 
	BEGIN 
		if @LanguageBranch IS NOT NULL
			RAISERROR('Language branch %s is not defined',16,1, @LanguageBranch)
		else
			SET @LangBranchID = -1
	END
	
	DECLARE @categoryTable AS TABLE (fkCategoryID int)
	IF NOT @CategoryList IS NULL
	BEGIN
		INSERT INTO @categoryTable
		EXEC netCategoryStringToTable @CategoryList=@CategoryList
	END
	IF @CategoryList IS NULL
		SELECT DISTINCT(tblProperty.fkPageID)
		FROM tblProperty
		INNER JOIN tblPageDefinition ON tblPageDefinition.pkID=tblProperty.fkPageDefinitionID
		INNER JOIN tblTree ON tblTree.fkChildID=tblProperty.fkPageID
		INNER JOIN tblPageLanguage ON tblPageLanguage.fkPageID=tblProperty.fkPageID
		INNER JOIN tblPageType ON tblPageDefinition.fkPageTypeID=tblPageType.pkID
		WHERE tblPageType.ContentType = 0 
		AND tblTree.fkParentID=@PageID 
		AND tblPageDefinition.Name=@PropertyName
		AND Property = 8		
		AND (@LangBranchID=-1 OR tblProperty.fkLanguageBranchID=@LangBranchID OR tblPageDefinition.LanguageSpecific<3)
		AND (
					SELECT Count(tblCategoryPage.fkPageID)
					FROM tblCategoryPage
					INNER JOIN tblPageDefinition ON tblPageDefinition.pkID = tblCategoryPage.CategoryType
					WHERE tblCategoryPage.CategoryType=tblProperty.fkPageDefinitionID
					AND tblCategoryPage.fkPageID=tblProperty.fkPageID
					AND (@LangBranchID=-1 OR tblCategoryPage.fkLanguageBranchID=@LangBranchID OR tblPageDefinition.LanguageSpecific<3)
			)=0	
			
				
	ELSE
		IF @Equals=1
			SELECT DISTINCT(tblProperty.fkPageID)
			FROM tblProperty
			INNER JOIN tblPageDefinition ON tblPageDefinition.pkID=tblProperty.fkPageDefinitionID
			INNER JOIN tblTree ON tblTree.fkChildID=tblProperty.fkPageID
			INNER JOIN tblPageLanguage ON tblPageLanguage.fkPageID=tblProperty.fkPageID
			INNER JOIN tblPageType ON tblPageDefinition.fkPageTypeID=tblPageType.pkID
			WHERE tblPageType.ContentType = 0 
			AND tblTree.fkParentID=@PageID 
			AND tblPageDefinition.Name=@PropertyName
			AND Property = 8		
			AND (@LangBranchID=-1 OR tblProperty.fkLanguageBranchID=@LangBranchID OR tblPageDefinition.LanguageSpecific<3)
			AND EXISTS
					(SELECT *
					FROM tblCategoryPage 
					INNER JOIN @categoryTable ct ON tblCategoryPage.fkCategoryID=ct.fkCategoryID
					INNER JOIN tblPageDefinition ON tblPageDefinition.pkID = tblCategoryPage.CategoryType
					WHERE tblCategoryPage.fkPageID=tblProperty.fkPageID AND tblCategoryPage.CategoryType=tblProperty.fkPageDefinitionID
					AND (@LangBranchID=-1 OR tblCategoryPage.fkLanguageBranchID=@LangBranchID OR tblPageDefinition.LanguageSpecific<3))
		ELSE
			SELECT DISTINCT(tblProperty.fkPageID)
			FROM tblProperty
			INNER JOIN tblPageDefinition ON tblPageDefinition.pkID=tblProperty.fkPageDefinitionID
			INNER JOIN tblTree ON tblTree.fkChildID=tblProperty.fkPageID
			INNER JOIN tblPageLanguage ON tblPageLanguage.fkPageID=tblProperty.fkPageID
			INNER JOIN tblPageType ON tblPageDefinition.fkPageTypeID=tblPageType.pkID
			WHERE tblPageType.ContentType = 0 
			AND tblTree.fkParentID=@PageID 
			AND tblPageDefinition.Name=@PropertyName
			AND Property = 8		
			AND (@LangBranchID=-1 OR tblProperty.fkLanguageBranchID=@LangBranchID OR tblPageDefinition.LanguageSpecific<3)
			AND NOT EXISTS
					(SELECT *
					FROM tblCategoryPage 
					INNER JOIN @categoryTable ct ON tblCategoryPage.fkCategoryID=ct.fkCategoryID
					INNER JOIN tblPageDefinition ON tblPageDefinition.pkID = tblCategoryPage.CategoryType
					WHERE tblProperty.fkPageID=tblCategoryPage.fkPageID AND tblCategoryPage.CategoryType=tblProperty.fkPageDefinitionID
					AND (@LangBranchID=-1 OR tblCategoryPage.fkLanguageBranchID=@LangBranchID OR tblPageDefinition.LanguageSpecific<3))
END
GO

PRINT N'Altering [dbo].[netPropertySearchCategoryMeta]...';
GO

ALTER PROCEDURE dbo.netPropertySearchCategoryMeta
(
	@PageID			INT,
	@PropertyName 	NVARCHAR(255),
	@Equals			BIT = 0,
	@NotEquals		BIT = 0,
	@CategoryList	NVARCHAR(2000) = NULL,
	@LanguageBranch		NCHAR(17) = NULL
)
AS
BEGIN
	DECLARE @LangBranchID NCHAR(17);
	
	DECLARE @categoryTable AS TABLE (fkCategoryID int)
	IF NOT @CategoryList IS NULL
	BEGIN
		INSERT INTO @categoryTable
		EXEC netCategoryStringToTable @CategoryList=@CategoryList
	END
	SELECT fkChildID
	FROM tblTree
	INNER JOIN tblContent WITH (NOLOCK) ON tblTree.fkChildID=tblContent.pkID
	WHERE tblContent.ContentType = 0 AND tblTree.fkParentID=@PageID 
	AND
    	(
		(@CategoryList IS NULL AND 	(
							SELECT Count(tblCategoryPage.fkPageID)
							FROM tblCategoryPage
							WHERE tblCategoryPage.CategoryType=0
							AND tblCategoryPage.fkPageID=tblTree.fkChildID
						)=0
		)
		OR
		(@Equals=1 AND tblTree.fkChildID IN
						(SELECT tblCategoryPage.fkPageID 
						FROM tblCategoryPage 
						INNER JOIN @categoryTable ct ON tblCategoryPage.fkCategoryID=ct.fkCategoryID 
						WHERE tblCategoryPage.CategoryType=0)
		)
		OR
		(@NotEquals=1 AND tblTree.fkChildID NOT IN
						(SELECT tblCategoryPage.fkPageID 
						FROM tblCategoryPage 
						INNER JOIN @categoryTable ct ON tblCategoryPage.fkCategoryID=ct.fkCategoryID 
						WHERE tblCategoryPage.CategoryType=0)
		)
	)
END
GO

ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7034
GO

PRINT N'Update complete.';
GO
