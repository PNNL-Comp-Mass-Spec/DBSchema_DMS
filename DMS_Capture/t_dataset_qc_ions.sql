/****** Object:  Table [dbo].[t_dataset_qc_ions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_dataset_qc_ions](
	[dataset_id] [int] NOT NULL,
	[mz] [float] NOT NULL,
	[max_intensity] [real] NULL,
	[median_intensity] [real] NULL,
 CONSTRAINT [pk_t_dataset_qc_ions_dataset_id] PRIMARY KEY CLUSTERED 
(
	[dataset_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
