<?php
test('health works', function () { $response = $this->get('/api/health'); $response->assertStatus(200)->assertJson(['status'=>'ok']); });
