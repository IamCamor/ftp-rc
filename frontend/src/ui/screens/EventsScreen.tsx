import { useState } from "react";
import { Container, Typography } from "@mui/material";
import EventForm from "../components/forms/EventForm";
export default function EventsScreen(){ return <Container sx={{py:3}}><Typography variant="h5" gutterBottom>События</Typography><EventForm/></Container>; }
