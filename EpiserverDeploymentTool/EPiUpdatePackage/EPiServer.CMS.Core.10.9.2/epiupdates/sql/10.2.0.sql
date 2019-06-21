--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7039)
				select 0, 'Already correct database version'
            else if (@ver = 7038)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery


GO
PRINT N'Altering [dbo].[netPropertyDefinitionDelete]...';


GO
ALTER PROCEDURE [dbo].[netPropertyDefinitionDelete]
(
	@PropertyDefinitionID INT
)
AS
BEGIN
	DECLARE @ScopedProperties TABLE (ScopeName nvarchar(450))
	INSERT INTO @ScopedProperties SELECT * FROM dbo.GetExistingScopesForDefinition(@PropertyDefinitionID) 
	DELETE FROM tblContentProperty WHERE ScopeName IN (SELECT ScopeName FROM @ScopedProperties) 
	DELETE FROM tblWorkContentProperty WHERE ScopeName IN (SELECT ScopeName FROM @ScopedProperties)
	DELETE FROM tblPropertyDefault WHERE fkPageDefinitionID=@PropertyDefinitionID
	DELETE FROM tblProperty WHERE fkPageDefinitionID=@PropertyDefinitionID
	DELETE FROM tblWorkProperty WHERE fkPageDefinitionID=@PropertyDefinitionID
	DELETE FROM tblCategoryPage WHERE CategoryType=@PropertyDefinitionID
	DELETE FROM tblWorkCategory WHERE CategoryType=@PropertyDefinitionID
	DELETE FROM tblPageDefinition WHERE pkID=@PropertyDefinitionID
END


GO
PRINT N'Altering [dbo].[GetExistingScopesForDefinition]...';


GO
ALTER FUNCTION [dbo].[GetExistingScopesForDefinition] 
(
	@PropertyDefinitionID int
)
RETURNS @ScopedPropertiesTable TABLE 
(
	ScopeName nvarchar(450)
)
AS
BEGIN
	--Get blocktype if property is block property
	DECLARE @ContentTypeID INT;
	SET @ContentTypeID = (SELECT tblContentType.pkID FROM 
		tblPropertyDefinition
		INNER JOIN tblPropertyDefinitionType ON tblPropertyDefinition.fkPropertyDefinitionTypeID = tblPropertyDefinitionType.pkID
		INNER JOIN tblContentType ON tblPropertyDefinitionType.fkContentTypeGUID = tblContentType.ContentTypeGUID
		WHERE tblPropertyDefinition.pkID = @PropertyDefinitionID);
		
	IF (@ContentTypeID IS NOT NULL)
	BEGIN
		INSERT INTO @ScopedPropertiesTable
		SELECT DISTINCT Property.ScopeName FROM
			tblWorkContentProperty as Property WITH(INDEX(IDX_tblWorkContentProperty_ScopeName))
			INNER JOIN dbo.GetScopedBlockProperties(@ContentTypeID) as ScopedProperties ON 
				Property.ScopeName LIKE (ScopedProperties.ScopeName + '%')
				WHERE ScopedProperties.ScopeName LIKE ('%.' + CAST(@PropertyDefinitionID as VARCHAR)+ '.')
	END
	
	RETURN 
END


GO
PRINT N'Altering [dbo].[sp_DatabaseVersion]...';


GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7039
GO

PRINT N'Update complete.';


GO