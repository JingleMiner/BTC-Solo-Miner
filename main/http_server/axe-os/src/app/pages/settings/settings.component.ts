import { HttpErrorResponse, HttpEventType } from '@angular/common/http';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
//import { ToastrService } from 'ngx-toastr';
//import { FileUploadHandlerEvent } from 'primeng/fileupload';
import { map, Observable, catchError, of, shareReplay, startWith } from 'rxjs';
import { GithubUpdateService } from '../../services/github-update.service';
import { LoadingService } from '../../services/loading.service';
import { SystemService } from '../../services/system.service';
import { eASICModel } from '../../models/enum/eASICModel';
import { NbToastrService } from '@nebular/theme';

@Component({
  selector: 'app-settings',
  templateUrl: './settings.component.html',
  styleUrls: ['./settings.component.scss']
})
export class SettingsComponent {

  public firmwareUpdateProgress: number | null = 0;
  public websiteUpdateProgress: number | null = 0;

  public deviceModel: string = "";
  public devToolsOpen: boolean = false;
  public eASICModel = eASICModel;
  public ASICModel!: eASICModel;

  public checkLatestRelease: boolean = false;
  public latestRelease$: Observable<any>;
  public expectedFileName: string = "";

  public selectedFirmwareFile: File | null = null;
  public selectedWebsiteFile: File | null = null;

  public info$: Observable<any>;

  public isWebsiteUploading = false;
  public isFirmwareUploading = false;


  constructor(
    private systemService: SystemService,
    private toastrService: NbToastrService,
    private loadingService: LoadingService,
    private githubUpdateService: GithubUpdateService
  ) {

    window.addEventListener('resize', this.checkDevTools);
    this.checkDevTools();

    this.latestRelease$ = this.githubUpdateService.getReleases().pipe(map(releases => {
      return releases[0];
    }));

    this.info$ = this.systemService.getInfo(0).pipe(shareReplay({ refCount: true, bufferSize: 1 }))

    this.info$.pipe(this.loadingService.lockUIUntilComplete())
      .subscribe(info => {
        this.deviceModel = info.deviceModel;
        this.ASICModel = info.ASICModel;
      });
  }

  private checkDevTools = () => {
    if (
      window.outerWidth - window.innerWidth > 160 ||
      window.outerHeight - window.innerHeight > 160
    ) {
      this.devToolsOpen = true;
    } else {
      this.devToolsOpen = false;
    }
  };

  // 文件上传相关方法保持不变
  public onFirmwareFileSelected(event: any): void {
    const file: File = event.target.files[0];
    if (file) {
      this.selectedFirmwareFile = file;
    }
  }

  public uploadFirmwareFile(): void {
    if (this.selectedFirmwareFile) {
      this.isFirmwareUploading = true;
      this.firmwareUpdateProgress = 0;

      this.systemService.performOTAUpdate(this.selectedFirmwareFile).subscribe({
        next: (event) => {
          if (event.type === HttpEventType.UploadProgress) {
            this.firmwareUpdateProgress = Math.round(100 * event.loaded / (event.total || 1));
          } else if (event.type === HttpEventType.Response) {
            this.firmwareUpdateProgress = 100;
            this.isFirmwareUploading = false;
            this.toastrService.success('Success!', 'Firmware uploaded successfully.');
          }
        },
        error: (err: HttpErrorResponse) => {
          this.isFirmwareUploading = false;
          this.firmwareUpdateProgress = 0;
          this.toastrService.danger('Error.', `Could not upload firmware. ${err.message}`);
        }
      });
    }
  }

  public onWebsiteFileSelected(event: any): void {
    const file: File = event.target.files[0];
    if (file) {
      this.selectedWebsiteFile = file;
    }
  }

  public uploadWebsiteFile(): void {
    if (this.selectedWebsiteFile) {
      this.isWebsiteUploading = true;
      this.websiteUpdateProgress = 0;

      this.systemService.performWWWOTAUpdate(this.selectedWebsiteFile).subscribe({
        next: (event) => {
          if (event.type === HttpEventType.UploadProgress) {
            this.websiteUpdateProgress = Math.round(100 * event.loaded / (event.total || 1));
          } else if (event.type === HttpEventType.Response) {
            this.websiteUpdateProgress = 100;
            this.isWebsiteUploading = false;
            this.toastrService.success('Success!', 'Website uploaded successfully.');
          }
        },
        error: (err: HttpErrorResponse) => {
          this.isWebsiteUploading = false;
          this.websiteUpdateProgress = 0;
          this.toastrService.danger('Error.', `Could not upload website. ${err.message}`);
        }
      });
    }
  }
}
