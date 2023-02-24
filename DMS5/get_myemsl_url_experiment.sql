/****** Object:  UserDefinedFunction [dbo].[GetMyEMSLUrlExperiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetMyEMSLUrlExperiment]
/****************************************************
**
**  Desc:
**      Generates the MyEMSL URL required for viewing items stored for a given experiment
**
**  Auth:   mem
**  Date:   09/12/2013
**
*****************************************************/
(
    @ExperimentName varchar(128)
)
RETURNS varchar(1024)
AS
BEGIN
    Declare @KeyName varchar(128) = 'extended_metadata.gov_pnnl_emsl_dms_experiment.name.untouched'
    Declare @Url varchar(1024) = dbo.GetMyEMSLUrlWork(@KeyName, @ExperimentName)

    Return @Url
END

GO
GRANT VIEW DEFINITION ON [dbo].[GetMyEMSLUrlExperiment] TO [DDL_Viewer] AS [dbo]
GO
