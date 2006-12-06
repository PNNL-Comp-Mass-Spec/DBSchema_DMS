/****** Object:  Table [dbo].[T_Mass_Correction_Factors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Mass_Correction_Factors](
	[Mass_Correction_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Mass_Correction_Tag] [char](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Monoisotopic_Mass_Correction] [float] NOT NULL,
	[Average_Mass_Correction] [float] NULL,
	[Affected_Atom] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Mass_Correction_Factors_Affected_Atom]  DEFAULT ('-'),
	[Original_Source] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Mass_Correction_Factors_Original_Source]  DEFAULT (''),
	[Original_Source_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Mass_Correction_Factors_Original_Source_Name]  DEFAULT (''),
	[Alternative_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Mass_Correction_Factors] PRIMARY KEY CLUSTERED 
(
	[Mass_Correction_ID] ASC
) ON [PRIMARY],
 CONSTRAINT [IX_T_Mass_Correction_Factors_MonoisotopicMass_and_AffectedAtom] UNIQUE NONCLUSTERED 
(
	[Monoisotopic_Mass_Correction] ASC,
	[Affected_Atom] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Mass_Correction_Factors_Mass_Correction_Tag] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Mass_Correction_Factors_Mass_Correction_Tag] ON [dbo].[T_Mass_Correction_Factors] 
(
	[Mass_Correction_Tag] ASC
) ON [PRIMARY]
GO

/****** Object:  Trigger [dbo].[trig_i_Mass_Correction_Factors] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE Trigger trig_i_Mass_Correction_Factors on dbo.T_Mass_Correction_Factors
For Insert
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Mass_Correction_Factors_Change_History (
				Mass_Correction_ID, Mass_Correction_Tag, Description, 
			    Monoisotopic_Mass_Correction, Average_Mass_Correction, 
			    Affected_Atom, Original_Source, Original_Source_Name, 
				Monoisotopic_Mass_Change, Average_Mass_Change, 
				Entered, Entered_By)
	SELECT 	Mass_Correction_ID, Mass_Correction_Tag, Description, 
		    Monoisotopic_Mass_Correction, Average_Mass_Correction, 
		    Affected_Atom, Original_Source, Original_Source_Name, 
			0 AS Monoisotopic_Mass_Change, 0 AS Average_Mass_Change, 
			GetDate(), SYSTEM_USER
	FROM inserted



GO

/****** Object:  Trigger [dbo].[trig_u_Mass_Correction_Factors] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE Trigger trig_u_Mass_Correction_Factors on dbo.T_Mass_Correction_Factors
For Update
AS
	If @@RowCount = 0
		Return

	if update(Mass_Correction_Tag) or 
	   update(Monoisotopic_Mass_Correction) or 
	   update(Average_Mass_Correction) or 
	   update(Affected_Atom)
		INSERT INTO T_Mass_Correction_Factors_Change_History (
					Mass_Correction_ID, Mass_Correction_Tag, Description, 
				    Monoisotopic_Mass_Correction, Average_Mass_Correction, 
				    Affected_Atom, Original_Source, Original_Source_Name, 
					Monoisotopic_Mass_Change, 
					Average_Mass_Change,
					Entered, Entered_By)
		SELECT 	inserted.Mass_Correction_ID, inserted.Mass_Correction_Tag, inserted.Description, 
			    inserted.Monoisotopic_Mass_Correction, inserted.Average_Mass_Correction, 
			    inserted.Affected_Atom, inserted.Original_Source, inserted.Original_Source_Name, 
				ROUND(inserted.Monoisotopic_Mass_Correction - deleted.Monoisotopic_Mass_Correction, 10),
				ROUND(inserted.Average_Mass_Correction - deleted.Average_Mass_Correction, 10),
				GetDate(), SYSTEM_USER
		FROM deleted INNER JOIN inserted ON deleted.Mass_Correction_ID = inserted.Mass_Correction_ID



GO
ALTER TABLE [dbo].[T_Mass_Correction_Factors]  WITH CHECK ADD  CONSTRAINT [CK_T_Mass_Correction_Factors_Tag] CHECK  ((((not([Mass_Correction_Tag] like '%:%'))) and ((not([Mass_Correction_Tag] like '%,%')))))
GO
ALTER TABLE [dbo].[T_Mass_Correction_Factors] CHECK CONSTRAINT [CK_T_Mass_Correction_Factors_Tag]
GO
