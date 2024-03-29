/****** Object:  Table [dbo].[T_Prep_LC_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Prep_LC_Run](
	[ID] [int] IDENTITY(1000,1) NOT NULL,
	[Prep_Run_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LC_Column] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LC_Column_2] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Guard_Column] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Created] [datetime] NOT NULL,
	[OperatorPRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Digestion_Method] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Prep_Requests] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Prep_Work_Packages] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Number_Of_Runs] [int] NULL,
	[Instrument_Pressure] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Storage_Path] [int] NULL,
	[Uploaded] [datetime] NULL,
	[Quality_Control] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Prep_LC_Run] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Prep_LC_Run] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Prep_LC_Run] ADD  CONSTRAINT [DF_T_Prep_LC_Run_Guard_Column]  DEFAULT ('No') FOR [Guard_Column]
GO
ALTER TABLE [dbo].[T_Prep_LC_Run] ADD  CONSTRAINT [DF_T_Prep_LC_Run_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Prep_LC_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Prep_LC_Run_T_Instrument_Name] FOREIGN KEY([Instrument])
REFERENCES [dbo].[T_Instrument_Name] ([IN_name])
GO
ALTER TABLE [dbo].[T_Prep_LC_Run] CHECK CONSTRAINT [FK_T_Prep_LC_Run_T_Instrument_Name]
GO
