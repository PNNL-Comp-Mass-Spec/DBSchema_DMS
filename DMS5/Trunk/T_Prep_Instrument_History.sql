/****** Object:  Table [dbo].[T_Prep_Instrument_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Prep_Instrument_History](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Instrument] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Date_Of_Change] [datetime] NULL,
	[Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Note] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NOT NULL,
	[EnteredBy] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Prep_Instrument_History] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Prep_Instrument_History] ADD  CONSTRAINT [DF_T_Prep_Instrument_History_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
