import { Component } from '@angular/core';

@Component({
  selector: 'ngx-footer',
  styleUrls: ['./footer.component.scss'],
  template: `
    <span class="created-by">
      Powered by <a href="https://jingleminer.com" target="_blank">JingleMiner</a>.
    </span>
  `,
})
export class FooterComponent {}
