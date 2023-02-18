/****** Object:  StoredProcedure [dbo].[store_quameter_results] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[store_quameter_results]
/****************************************************
**
**  Desc:
**      Updates the Quameter information for the dataset specified by @DatasetID
**      If @DatasetID is 0, then will use the dataset name defined in @ResultsXML
**      If @DatasetID is non-zero, then will validate that the Dataset Name in the XML corresponds
**      to the dataset ID specified by @DatasetID
**
**      Typical XML file contents:
**
**      <Quameter_Results>
**        <Dataset>Shew119-01_17july02_earth_0402-10_4-20</Dataset>
**        <Job>780000</Job>
**        <Measurements>
**          <Measurement Name="XIC-WideFrac">0.35347</Measurement>
**          <Measurement Name="XIC-FWHM-Q1">20.7009</Measurement>
**          <Measurement Name="XIC-FWHM-Q2">22.3192</Measurement>
**          <Measurement Name="XIC-FWHM-Q3">24.794</Measurement>
**          <Measurement Name="XIC-Height-Q2">1.08473</Measurement>
**          etc.
**        </Measurements>
**      </Quameter_Results>
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/17/2012 mem - Initial version (modelled after StoreSMAQCResults)
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**
*****************************************************/
(
    @DatasetID int = 0,                -- If this value is 0, then will determine the dataset name using the contents of @ResultsXML
    @ResultsXML xml,                -- XML holding the Quameter results for a single dataset
    @message varchar(255) = '' output,
    @infoOnly tinyint = 0
)
As
    set nocount on

    declare @myError int
    EXEC StoreQuameterResults @DatasetID, @ResultsXML, @message output, @infoOnly
    Return @myError

GO
