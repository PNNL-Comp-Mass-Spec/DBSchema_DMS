/****** Object:  Table [dbo].[T_Mass_Correction_Factors_Change_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Mass_Correction_Factors_Change_History](
	[Event_ID] [int] IDENTITY(1,1) NOT NULL,
	[Mass_Correction_ID] [int] NOT NULL,
	[Mass_Correction_Tag] [char](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Monoisotopic_Mass_Correction] [float] NOT NULL,
	[Average_Mass_Correction] [float] NULL,
	[Affected_Atom] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Original_Source] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Original_Source_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Monoisotopic_Mass_Change] [float] NULL,
	[Average_Mass_Change] [float] NULL,
	[Entered] [datetime] NOT NULL CONSTRAINT [DF_T_Mass_Correction_Factors_Change_History_Entered]  DEFAULT (getdate()),
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Mass_Correction_Factors_Change_History_Entered_By]  DEFAULT (suser_sname()),
 CONSTRAINT [PK_T_Mass_Correction_Factors_Change_History] PRIMARY KEY CLUSTERED 
(
	[Event_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
