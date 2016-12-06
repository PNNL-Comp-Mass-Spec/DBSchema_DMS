/****** Object:  Table [dbo].[T_EMSL_Instrument_Allocation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EMSL_Instrument_Allocation](
	[EUS_Instrument_ID] [int] NOT NULL,
	[Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[FY] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Allocated_Hours] [int] NULL,
	[Ext_Display_Name] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Ext_Requested_Hours] [int] NULL,
	[Last_Affected] [datetime] NULL,
 CONSTRAINT [PK_T_EMSL_Instrument_Allocation] PRIMARY KEY CLUSTERED 
(
	[EUS_Instrument_ID] ASC,
	[Proposal_ID] ASC,
	[FY] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_EMSL_Instrument_Allocation] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Allocation] ADD  CONSTRAINT [DF_T_EMSL_Instrument_Allocation_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
