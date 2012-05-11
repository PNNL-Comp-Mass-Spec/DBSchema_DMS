/****** Object:  StoredProcedure [dbo].[StringToBase64] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE StringToBase64 (@String VARCHAR(4000), @Base64 VARCHAR(4000) OUTPUT) AS

DECLARE @ByteArray INT, @OLEResult INT


EXECUTE @OLEResult = sp_OACreate 'ScriptUtils.ByteArray', @ByteArray OUT
IF @OLEResult <> 0 PRINT 'ScriptUtils.ByteArray problem'

--Set a charset if needed.
--execute @OLEResult = sp_OASetProperty @ByteArray, 'CharSet', "windows-1250"
--IF @OLEResult <> 0 PRINT 'CharSet problem'

--Set the string.
EXECUTE @OLEResult = sp_OASetProperty @ByteArray, 'String', @String
IF @OLEResult <> 0 PRINT 'String problem'

--Get base64
EXECUTE @OLEResult = sp_OAGetProperty @ByteArray, 'Base64', @Base64 OUTPUT
IF @OLEResult <> 0 PRINT 'Base64 problem'

EXECUTE @OLEResult = sp_OADestroy @ByteArray

print @OLEResult

GO
