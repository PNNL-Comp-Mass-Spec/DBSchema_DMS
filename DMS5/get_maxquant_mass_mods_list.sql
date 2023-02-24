/****** Object:  UserDefinedFunction [dbo].[GetMaxQuantMassModsList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetMaxQuantMassModsList]
/****************************************************
**
**  Desc:
**      Builds a delimited list of Mod names and IDs for the given MaxQuant parameter file
**
**  Return value: list of mass mods
**
**  Parameters:
**
**  Auth:   mem
**  Date:   03/05/2021 mem - Initial version
**
*****************************************************/
(
    @paramFileId int
)
RETURNS varchar(4000)
AS
BEGIN
    DECLARE @headers varchar(64) = '!Headers!Name:Mod_ID:Type:Residue:Mass'
    Declare @list varchar(4000) = @headers

    SELECT @list = @list + '|' + PlexMemberInfo
    FROM ( SELECT MQM.Mod_Title + ':' + Cast(MQM.Mod_ID AS varchar(12)) + ':' +
                    CASE PFMM.Mod_Type_Symbol
                        WHEN 'S' THEN 'Static'
                        WHEN 'D' THEN 'Dynamic'
                        WHEN 'T' THEN 'Static Terminal Peptide'
                        WHEN 'P' THEN 'Static Terminal Protein'
                        WHEN 'I' THEN 'Isotopic'
                        ELSE PFMM.Mod_Type_Symbol
                    END + ':' + R.Residue_Symbol + ':' + Cast(MCF.Monoisotopic_Mass AS varchar(12)) AS
                    PlexMemberInfo,
                    PFMM.Mod_Type_Symbol,
                    MQM.Mod_Title
           FROM T_Param_File_Mass_Mods PFMM
                INNER JOIN T_Residues R
                  ON PFMM.Residue_ID = R.Residue_ID
                INNER JOIN T_Mass_Correction_Factors MCF
                  ON PFMM.Mass_Correction_ID = MCF.Mass_Correction_ID
                INNER JOIN T_Seq_Local_Symbols_List SLS
                  ON PFMM.Local_Symbol_ID = SLS.Local_Symbol_ID
                INNER JOIN dbo.T_Param_Files PF
                  ON PFMM.Param_File_ID = PF.Param_File_ID
                INNER JOIN T_MaxQuant_Mods MQM
                  ON MQM.Mod_ID = PFMM.MaxQuant_Mod_ID
           WHERE PF.Param_File_ID = @paramFileId
        ) LookupQ
    ORDER BY LookupQ.Mod_Type_Symbol DESC, LookupQ.Mod_Title

    If ISNULL(@list,'') = '' OR @list = @headers
        Set @list = ''

    RETURN @list
END

GO
