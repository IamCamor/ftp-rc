import { Backdrop, CircularProgress } from "@mui/material";
export default function LoadingOverlay({open}:{open:boolean}){
  return (
    <Backdrop sx={{ color:"#fff", zIndex: (t)=>t.zIndex.drawer+1 }} open={open}>
      <CircularProgress />
    </Backdrop>
  );
}
