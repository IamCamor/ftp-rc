import { useState } from "react"
import { TextField, Button, MenuItem, Paper, Stack } from "@mui/material"

export default function AddCatchForm() {
  const [form, setForm] = useState({
    fish: "",
    weight: "",
    location: "",
    privacy: "public",
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value })
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    console.log("Submitting catch:", form)
    alert("Демо: улов добавлен!")
  }

  return (
    <Paper sx={{ p: 3, maxWidth: 500, margin: "auto" }}>
      <form onSubmit={handleSubmit}>
        <Stack spacing={2}>
          <TextField
            label="Вид рыбы"
            name="fish"
            value={form.fish}
            onChange={handleChange}
          />
          <TextField
            label="Вес (кг)"
            name="weight"
            value={form.weight}
            onChange={handleChange}
          />
          <TextField
            label="Место"
            name="location"
            value={form.location}
            onChange={handleChange}
          />
          <TextField
            select
            label="Приватность"
            name="privacy"
            value={form.privacy}
            onChange={handleChange}
          >
            <MenuItem value="public">Все</MenuItem>
            <MenuItem value="friends">Только друзья</MenuItem>
            <MenuItem value="private">Только я</MenuItem>
          </TextField>
          <Button type="submit" variant="contained">
            Добавить улов
          </Button>
        </Stack>
      </form>
    </Paper>
  )
}
