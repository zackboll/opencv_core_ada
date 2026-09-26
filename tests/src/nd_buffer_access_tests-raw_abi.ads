package ND_Buffer_Access_Tests.Raw_ABI is

   --  Validates opencv_core_mat_borrow_contiguous_data directly through the
   --  thin interop layer: null handles and outputs, safe failure outputs,
   --  2-D and genuine N-D byte counts, continuous and gapped views, and
   --  empty Mats.
   procedure Check;

end ND_Buffer_Access_Tests.Raw_ABI;
