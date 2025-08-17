import { useState } from "react";
import { Container, Typography } from "@mui/material";
import ClubForm from "../components/forms/ClubForm";
export default function ClubsScreen(){ return <Container sx={{py:3}}><Typography variant="h5" gutterBottom>Клубы</Typography><ClubForm/></Container>; }
