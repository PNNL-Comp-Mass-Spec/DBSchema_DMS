/****** Object:  StoredProcedure [dbo].[validate_protein_collection_params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[validate_protein_collection_params]
/****************************************************
**
**  Desc:   Validates the organism DB and/or protein collection options
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   08/26/2010
**          05/15/2012 mem - Now verifying that @organismDBName is 'na' if @protCollNameList is defined, or vice versa
**          09/25/2012 mem - Expanded @organismDBName and @organismName to varchar(128)
**          08/19/2013 mem - Auto-clearing @organismDBName if both @organismDBName and @protCollNameList are defined and @organismDBName is the auto-generated FASTA file for the specified protein collection
**          07/12/2016 mem - Now using a synonym when calling ValidateAnalysisJobProteinParameters in the Protein_Sequences database
**          04/11/2022 mem - Increase warning threshold for length of @protCollNameList to 4000
**
*****************************************************/
(
    @toolName varchar(64),                      -- If blank, then will assume @orgDbReqd=1
    @organismDBName varchar(128) output,
    @organismName varchar(128),
    @protCollNameList varchar(4000) output,     -- Will raise an error if over 4000 characters long; necessary since the Broker DB (DMS_Pipeline) has a 4000 character limit on analysis job parameter values
    @protCollOptionsList varchar(256) output,
    @ownerUsername varchar(64) = '',            -- Only required if the user chooses an "Encrypted" protein collection; as of August 2010 we don't have any encrypted protein collections
    @message varchar(255) = '' output,
    @debugMode tinyint = 0                      -- If non-zero then will display some debug info
)
As
    declare @myError int
    EXEC @myError = ValidateProteinCollectionParams @toolName, @organismDBName output, @organismName, @protCollNameList output, @protCollOptionsList output, @ownerUsername, @message output, @debugMode
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[validate_protein_collection_params] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[validate_protein_collection_params] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[validate_protein_collection_params] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[validate_protein_collection_params] TO [Limited_Table_Write] AS [dbo]
GO
