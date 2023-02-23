/****** Object:  StoredProcedure [dbo].[HashTest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[HashTest]
    /*
    (
    @parameter1 int = 5,
    @parameter2 datatype OUTPUT
    )
    */
AS
DECLARE @HashThis nvarchar(max);
SELECT @HashThis = CONVERT(nvarchar,'dslfdkjLK85kldhnv$n000#knf');
SELECT HashBytes('SHA1', @HashThis);

RETURN

GO
