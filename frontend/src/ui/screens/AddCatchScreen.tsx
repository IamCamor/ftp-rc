import { useState } from "react";
import { Container, Typography } from "@mui/material";
import AddCatchForm from "../components/forms/AddCatchForm";
export default function AddCatchScreen(){ return <Container sx={{py:3}}><Typography variant="h5" gutterBottom>Добавить улов</Typography><AddCatchForm/></Container>; }
