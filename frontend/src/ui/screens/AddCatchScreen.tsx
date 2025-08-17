import AddCatchForm from "../components/forms/AddCatchForm"
import { Container, Typography } from "@mui/material"

export default function AddCatchScreen() {
  return (
    <Container sx={{ pt: 3, pb: 10 }}>
      <Typography variant="h5" gutterBottom>
        Добавить улов
      </Typography>
      <AddCatchForm />
    </Container>
  )
}
